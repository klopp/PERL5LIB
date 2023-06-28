package Atomic::Resource::XML;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Try::Catch;
use XML::Hash::XS;

use Atomic::Resource::Data;
use base qw/Atomic::Resource::Data/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source} ссылка на скаляр с JSON
    В {params} МОЖЕТ быть:
        {quiet} не выводить предупреждения
        {id}
        {xml}   флаги XML::Hash::XS
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);

    # output in SCALAR only:
    delete $self->{params}->{xml}->{output};
    return $self;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    my $error = $self->SUPER::create_work_copy;
    $error and return $error;

    try {
        $self->{work} = xml2hash( $self->{work}, %{ $self->{params}->{xml} } );
    }
    catch {
        $error = sprintf 'XML :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} and $self->{work} = hash2xml( $self->{work}, %{ $self->{params}->{xml} } );
    }
    catch {
        $error = sprintf 'XML :: %s', $_;
    };
    return $error ? $error : $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__
