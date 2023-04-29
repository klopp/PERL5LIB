package Things::TieData;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Things::Const qw/:types/;
use Scalar::Util qw/blessed/;

# ------------------------------------------------------------------------------
sub new(;$)
{
    my ( $class, $data ) = @_;
    tie my $self, ( caller(0) )[0], { data => $data };
    return $self;
}

# ------------------------------------------------------------------------------
sub FETCH
{
    my ($self) = @_;
    return $self;
}

# ------------------------------------------------------------------------------
sub STORE
{
    my ( $self, $data ) = @_;

    my $ref = ref $data;
    if( !$ref or $ref =~/^$ARRAY|$HASH$/sm or blessed $ref ) {
        $self->{data} = $data;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ( $self, $data ) = @_;
    return;
}

# ------------------------------------------------------------------------------
sub TIESCALAR
{
    my ( $class, $data ) = @_;
    my $self = bless { data => $data }, $class;
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
