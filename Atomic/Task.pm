package Atomic::Task;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/cluck confess/;
use Things qw/trim/;
use Time::HiRes qw/gettimeofday/;

use lib q{..};
use Atomic::Resource::Base;

our $VERSION = 'v2.0';
our %TASKS;

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
        use Resource::MemFile;
        my $rfm = Resource::MemFile->new( { source => '/my/data/table.xyz', id => 'memfile', }, );

        # Сложная структура данных:
        use Resource::Data;
        my $data = { ... };
        my $rd = Resource::Data->new( { source => \$data, id => 'data', }, );

        my $task = MyTask->new( [ $rfm, $rd, ], { mutex => Mutex::Mutex->new, }, );
        $task->run;
        exit;

        package MyTask;
        use AtomicTaskPP;
        use base qw/AtomicTaskPP/;

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
            #       что-то делаем с данными : $data, 
            #       $data->modified; (если менялось)
            #
            #       что-то делаем с содержимым файла в памяти: $memfile,
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

    if ( $params->{mutex} ) {
        $params->{mutex}->can('lock')   or confess 'Error: {mutex} can not lock()!';
        $params->{mutex}->can('unlock') or confess 'Error: {mutex} can not unlock()!';
    }
    else {
        $params->{quiet}
            or cluck 'Warning: no {mutex} in {params}, multi-threaded code may not be safe!';
    }

    my %data = (
        resources => $resources,
        params    => $params,
        id        => $params->{id},
    );
    delete $data{params}->{id};
    $data{id} or $data{id} = join q{.}, ( gettimeofday() );
    exists $TASKS{ $data{id} } and confess sprintf 'Error: task ID "%s" already exists!', $data{id};

    my $self = bless \%data, $class;
    %{ $self->{_res} } = map { $_->{id} => $_ } @{$resources};
    my $error = $self->check_params;
    $error and confess sprintf 'Error: invalid parameters: %s', $error;
    $TASKS{ $self->{id} } = $self;
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
    return $self->{_res}->{$id};
}

# ------------------------------------------------------------------------------
sub wget
{
    my ( $self, $id ) = @_;
    return exists $self->{_res}->{$id} ? $self->{_res}->{$id}->{work} : undef;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;

    my $error;

    if ( $self->{params}->{mutex} && !$self->{params}->{commit_lock} ) {
        $error = $self->{params}->{mutex}->lock;
        $error and return confess sprintf "Error locking task: %s\n", trim($error);
    }
    for ( 0 .. @{ $self->{resources} } - 1 ) {
        my $rs = $self->{resources}->[$_];

=for comment
    Создаём рабочую копию ресурса
=cut

        $error = $rs->create_work_copy;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

        if ($error) {
            $_ and $self->_delete_works( $_ - 1 );
            return confess sprintf "Error creating work copy: %s\n", trim($error);
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
        return confess sprintf "Error executing task: %s\n", trim($error);
    }

=for comment
    Меняем оригинальные ресурсы на модифицированные
=cut

    if ( $self->{params}->{mutex} && $self->{params}->{commit_lock} ) {
        $error = $self->{params}->{mutex}->lock;
        if ($error) {
            $self->_delete_works;
            return confess sprintf "Error locking commit: %s\n", trim($error);
        }
    }
    for ( 0 .. @{ $self->{resources} } - 1 ) {
        my $rs = $self->{resources}->[$_];
        if ( $rs->is_modified ) {
            $error = $rs->create_backup_copy;
            if ($error) {
                $self->_rollback($_);
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return confess sprintf "Error creating backup copy: %s\n", trim($error);
            }

            $error = $rs->commit;

=for comment
    При ошибке откатываемся на резервные копии
=cut

            if ($error) {
                $self->_rollback($_);
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return confess sprintf "Error commit changes: %s\n", trim($error);
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
    my ( $self, $i ) = @_;
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        my $rs = $self->{resources}->[$_];
        next unless $rs;
        if ( $rs->is_modified ) {
            $rs->rollback;
            $rs->delete_bakup_copy;
        }
        $rs->delete_work_copy;
    }
    return;
}

# ------------------------------------------------------------------------------
sub _delete_backups
{
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        $_->is_modified and $_->delete_backup_copy;
    }
    return;
}

# ------------------------------------------------------------------------------
sub _delete_works
{
    my ( $self, $i ) = @_;
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->delete_work_copy;
    }
    return $i;
}

# ------------------------------------------------------------------------------
1;
__END__
