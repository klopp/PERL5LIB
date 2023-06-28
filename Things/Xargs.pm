package Things::Xargs;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/xargs selfopt/;
our $VERSION = 'v1.0';

use Scalar::Util qw/blessed/;
use Try::Catch;

use Things::Const qw/:types/;

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub xargs
{
    my $args;
    if ( @_ == 1 ) {
        if ( ref $_[0] eq $HASH ) {
            $args = shift;
        }
        else {
            Carp::croak sprintf 'Not a %s reference!', $HASH;
        }
    }
    elsif ( @_ % 2 ) {
        Carp::croak sprintf 'Not a %s!', $HASH;
    }
    else {
        %{$args} = @_;
    }
    return $args;
}

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub selfopt
{
    my ( $self, @args, $opt ) = ( shift, @_ );

    try {
        ( ref $self eq $HASH || blessed $self )
            || Carp::croak sprintf 'First argument must be blessed or a %s reference!', $HASH;
        $opt = xargs(@args);
    }
    catch {
        $self->{error} = $_;
    };
    return $opt;
}

# ------------------------------------------------------------------------------
1;
__END__
