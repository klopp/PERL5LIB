package Things::Trim;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/trim/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use lib q{.};
use Things::Const qw/:types/;
use Scalar::Util qw/readonly/;

# ------------------------------------------------------------------------------
sub trim
{
    CORE::state $TRIM_RX = qr{^\s+|\s+$};

    my @rc;
    for (@_) {

        if ( ref $_ eq $ARRAY ) {
            push @rc, trim($_) for @{$_};
        }
        elsif ( ref $_ eq $HASH ) {
            while ( my ($key) = each %{$_} ) {
                push @rc, $key, trim( $_->{$key} );
            }
        }
        elsif ( !ref $_ ) {
            my $s = $_;
            $s =~ s/$TRIM_RX//gsm;
            push @rc, $s;
            $_ = $s unless readonly $_;
        }
    }
    return wantarray ? @rc : \@rc;
}

# ------------------------------------------------------------------------------
1;
