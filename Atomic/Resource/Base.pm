package Atomic::Resource::Base;

# ------------------------------------------------------------------------------
use threads;
use threads::shared;
use Modern::Perl;

use Carp qw/confess/;
use Things qw/set_bool/;
use UUID qw/uuid/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------

=for comment
    Базовый класс для работы с ресурсами. Обеспечивает:
    * создание резервной копии ресурса для отката изменений
    * создание рабочей копии ресурса, в которой производятся все изменения
    * замену ресурса на рабочую копию поле внесения изменений
    * замену ресурса на резервную копию при неудаче предыдущего пункта
=cut

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source}
    В {params} МОЖЕТ быть:
        {quiet} не выводить предупреждения
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}     рабочие данные
        {backup}   копия исходных данных
=cut

    my ( $class, $params ) = @_;
    $params //= {};
    ref $params eq 'HASH' or confess 'Error: invalid {params} value.';
    $params->{source}     or confess 'Error: no {source} in {params}.';

    #    my %data :shared;

    my %data;

    $data{params}   = $params;
    $data{modified} = 0;
    $data{backup}   = undef;
    $data{work}     = undef;
    $data{id}       = $params->{id} || uuid;

    #    share(%data);
    %data = %{ shared_clone( \%data ) };

=for comment
    = (
        params   => $params,
        modified => 0,
        backup   => undef,
        work     => undef,
        id       => $params->{id},
    );
    delete $data{params}->{id};
    $data{id} or $data{id} = uuid;
=cut

    my $self = bless \%data, $class;

=for comment
    $self->{params}   = $params;
    $self->{modified} = 0;
    $self->{backup}   = undef;
    $self->{work}     = undef;
    $self->{id}       = $params->{id};
    delete $self->{params}->{id};
    $self->{id} or $self->{id} = uuid;   
=cut

    my $error = $self->check_params;
    $error and confess sprintf 'Error: invalid parameters: %s', $error;
    return $self;
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{id};
}

# ------------------------------------------------------------------------------
sub modified
{
    my $self = shift;
    return set_bool( \$self->{modified}, @_ ? shift : 1 );
}

# ------------------------------------------------------------------------------
sub is_modified
{
    my ($self) = @_;
    return $self->{modified};
}

# ------------------------------------------------------------------------------
sub _emethod
{
    my ($self) = @_;
    return confess sprintf 'Error: method "error = %s()" must be overloaded.', ( caller 1 )[3];
}

# ------------------------------------------------------------------------------
sub check_params
{

=for comment
    Проверка входных параметров. МОЖЕТ быть перегружен в 
    производных объектах.
    NB! Проверка НАЛИЧИЯ {params}->{source} происходит в базовом конструкторе.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{

=for comment
    Создание копии ресурса для отката. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{

=for comment
    Удаление копии ресурса для отката. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{

=for comment
    Создание рабочей копии ресурса для модификации. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{

=for comment
    Удаление рабочей копии ресура. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub commit
{

=for comment
    Замена ресурса на рабочую копию. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub rollback
{

=for comment
    Замена ресурса на резервную копию. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
1;
__END__
