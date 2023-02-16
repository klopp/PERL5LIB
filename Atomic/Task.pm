package Atomic::TaskPool;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Array::Utils qw/intersect/;
use Carp qw/cluck confess/;
use Const::Fast;
use Things qw/trim/;
use UUID qw/uuid/;

use lib q{..};
use Atomic::Resource::Base;

const my $ELOCK   => 1;
const my $EWORK   => 2;
const my $EEXEC   => 3;
const my $ECLOCK  => 4;
const my $EBACKUP => 5;
const my $ECOMMIT => 6;

use Exporter;

our @EXPORT  = qw/$ELOCK $EWORK $EEXEC $ECLOCK $EBACKUP $ECOMMIT/;
our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------

=for comment
    Базовый класс, реализующий псевдо-атомарную задачу. На входе принимает массив
    потенциально изменяемых ресурсов, см. соответствующие классы Resource::*.
    * Создаёт резервные копии ресурсов для отката изменений (rollback)
    * Создаёт рабочие копии ресурсов
    * Вызывает перегруженный метод execute()
    * Заменяет ресурсы изменёнными рабочими копиями если ошибок не случилось (commit)
    * В случае ошибок на этапе коммита откатывает затронутые ресурсы на 
        резервные копии

    Схема использования:

        # Файл отмапленный в память:
        use Atomic::Resource::MemFile;
        my $rfm = Atomic::Resource::MemFile->new( { source => '/my/data/table.xyz', id => 'memfile', }, );

        # Сложная структура данных:
        use Atomic::Resource::Data;
        my $data = { ... };
        my $rd = Atomic::Resource::Data->new( { source => \$data, id => 'data', }, );

        my $task = MyTask->new( [ $rfm, $rd, ], { ecb => sub { ... }, mutex => Mutex::Mutex->new, }, );
        $task->run;
        exit;

        package MyTask;
        use Atomic::Task;
        use base qw/Atomic::Task/;

        sub execute
        {
            my ($self) = @_;

            my $memfile = $self->wget( 'memfile' );
            my $data    = $self->wget( 'data' );
            #
            # Что здесь доступно для каждого типа ресурсов
            #   описано в соответствующих исходниках.
            #   Основное (а другого и не нужно):
            #
            #       что-то делаем с данными : $data->{work}, 
            #       $data->modified; (если менялось)
            #
            #       что-то делаем с содержимым файла в памяти: $memfile->{work},
            #       $memfile->modified; (если менялось)
            #            
            return;
        }       
=cut

# ------------------------------------------------------------------------------
sub new
{

=for comment
    На входе ДОЛЖНО быть:
        {resources} [ Resource::*, ...] 
    В {params} МОЖЕТ быть:
        {mutex}
        {commit_lock} лочить только коммит
        {quiet}       не выводить предупреждения
        {id}
    Структура после полной инициализации:
        {resources}
        {params}
        {id}
=cut    

    my ( $class, $resources, $params ) = @_;

    $params //= {};
    ref $params eq 'HASH'                          or confess 'Error: invalid {params} value';
    ( ref $resources eq 'ARRAY' && @{$resources} ) or confess 'Error: invalid {resources} value';
    ( ref $params->{ecb} eq 'CODE' )               or confess 'Error: invalid {ecb} value';

    if ( $params->{mutex} ) {
        $params->{mutex}->can('lock')   or confess 'Error: {mutex} can not lock()!';
        $params->{mutex}->can('unlock') or confess 'Error: {mutex} can not unlock()!';
    }
    else {
        $params->{quiet}
            or cluck 'Warning: no {mutex} in {params}, multi-threaded code may not be safe!';
    }

    my %data = (
        params      => $params,
        id          => $params->{id} || uuid,
        lock_commit => $params->{commit_lock},
        resources   => { map { $_->{id} => $_ } @{$resources} },
    );
    my $self  = bless \%data, $class;
    my $error = $self->check_params;
    $error and confess sprintf 'Error: invalid parameters: %s', $error;
    return $self;
}

# ------------------------------------------------------------------------------
sub check_params
{

=for comment
    Проверка входных параметров. МОЖЕТ быть перегружен в 
    производных объектах.
    NB! Корректность {params}->{mutex} и других основных входных параметров 
    происходит в базовом конструкторе.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return;
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{id};
}

# ------------------------------------------------------------------------------
sub rget
{
    my ( $self, $id ) = @_;
    return $self->{resources}->{$id};
}

# ------------------------------------------------------------------------------
sub wget
{
    my ( $self, $id ) = @_;
    return exists $self->{resources}->{$id} ? $self->{resources}->{$id}->{work} : undef;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;

    my $error;

    if ( $self->{params}->{mutex} && !$self->{params}->{commit_lock} ) {
        $error = $self->{params}->{mutex}->lock;
        $error
            and return $self->{params}->{ecb}->( $self, $ELOCK, trim($error) );
    }

    while ( my ( undef, $resource ) = each %{ $self->{resources} } ) {

=for comment
    Создаём рабочую копию ресурса
=cut

        $error = $resource->create_work_copy;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

        if ($error) {
            $_ and $self->_delete_works;
            return $self->{params}->{ecb}->( $self, $EWORK, trim($error) );
        }
    }

=for comment
    Модифицируем реурсы
=cut

    $error = $self->execute;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

    if ($error) {
        $self->{params}->{mutex}->unlock if $self->{params}->{mutex} && !$self->{params}->{commit_lock};
        $self->_delete_works;
        return $self->{params}->{ecb}->( $self, $EEXEC, trim($error) );
    }

=for comment
    Меняем оригинальные ресурсы на модифицированные
=cut

    if ( $self->{params}->{mutex} && $self->{params}->{commit_lock} ) {
        $error = $self->{params}->{mutex}->lock;
        if ($error) {
            $self->_delete_works;
            return $self->{params}->{ecb}->( $self, $ECLOCK, trim($error) );
        }
    }

    while ( my ( undef, $resource ) = each %{ $self->{resources} } ) {
        if ( $resource->is_modified ) {
            $error = $resource->create_backup_copy;
            if ($error) {
                $self->_rollback;
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return $self->{params}->{ecb}->( $self, $EBACKUP, trim($error) );
            }

            $error = $resource->commit;

=for comment
    При ошибке откатываемся на резервные копии
=cut

            if ($error) {
                $self->_rollback;
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return $self->{params}->{ecb}->( $self, $ECOMMIT, trim($error) );
            }
        }
    }
    $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
    $self->_delete_backups;
    $self->_delete_works;
    return;
}

# ------------------------------------------------------------------------------
sub execute
{

=for comment
    Основной метод для работы с ресурсами. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Если ресурс был модифицирован - должен выставлять у него {modified}.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return confess sprintf 'Error: method "error = %s()" must be overloaded', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub _rollback
{
    my ($self) = @_;
    while ( my ( undef, $resource ) = each %{ $self->{resources} } ) {
        if ( $resource->is_modified ) {
            $resource->rollback;
            $resource->delete_bakup_copy;
        }
        $resource->delete_work_copy;
    }
    return;
}

# ------------------------------------------------------------------------------
sub _delete_backups
{
    my ($self) = @_;
    while ( my ( undef, $resource ) = each %{ $self->{resources} } ) {
        $resource->is_modified and $resource->delete_backup_copy;
    }
    return;
}

# ------------------------------------------------------------------------------
sub _delete_works
{
    my ( $self, $i ) = @_;
    while ( my ( undef, $resource ) = each %{ $self->{resources} } ) {
        $resource->{work} and $resource->delete_work_copy;
    }
    return $i;
}

# ------------------------------------------------------------------------------
1;
__END__
