package Things::Trim;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/trim/;
our $VERSION = 'v1.0';
our $nomod;

# ------------------------------------------------------------------------------
use Things::Const qw/:types/;
use Scalar::Util qw/readonly/;

# ------------------------------------------------------------------------------
sub trim
{
    CORE::state $TRIM_RX = qr{^\s+|\s+$};

    my ( $src, $nomod ) = @_;
    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { trim( $_, $nomod ) } @{$src};
        if( !$nomod ) {
            readonly @_ or @_ = @{$dest};
        }
    }
    elsif ( ref $src eq $HASH ) {
        %{$dest} = map { $_ => trim( $src->{$_}, $nomod ) } keys %{$src};
        if ( !$nomod ) {
            readonly @_ or @_ = %{$dest};
        }
    }
    elsif ( ref \$src eq $SCALAR ) {
        $dest = $src;
        $dest =~ s/$TRIM_RX//gsm;
        if ( !$nomod ) {
            readonly $_[0] or $_[0] = $dest;
        }
    }
    else {
        Carp::cluck sprintf '%s() :: 1st argument must be %s REF, %s REF or %s', ( caller 0 )[3], $ARRAY, $HASH,
            $SCALAR;
    }
    return $dest;
}

# ------------------------------------------------------------------------------
1;
