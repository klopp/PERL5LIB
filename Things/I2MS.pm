package Things::I2MS;

use strict;
use warnings;
use base qw/Exporter/;
our @EXPORT  = qw/i2s interval_to_seconds i2ms interval_to_microseconds/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use Things::Const qw/:datetime/;

# ------------------------------------------------------------------------------
sub i2ms
{
    goto &interval_to_microseconds;
}

# ------------------------------------------------------------------------------
sub i2s
{
    goto &interval_to_seconds;
}

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub interval_to_seconds
{
    my $ms = interval_to_microseconds(shift);
    $ms or return;
    return int( $ms / $MICROSEC_IN_SEC );
}

# ------------------------------------------------------------------------------
# PART:
#   \d+i - microseconds, \d+s - seconds, \d+m - minutes, \d+h - hours, \d+d - days
# IN string:
#   PART[{, }PART...]
# Example:
#   "1d, 24m, 3h, 30s, 1200i"
# ------------------------------------------------------------------------------
sub interval_to_microseconds
{
    my ($interval) = @_;

    $interval or return;

    my $ms;
    my @parts;

    @parts = split /[,\s]+/sm, lc $interval;
    for (@parts) {
        return unless /^([\d_]+)([ismhd]?)$/ism;
        my $n = $1;
        $n =~ s/_//gsm;
        $n ne q{} or return;
        if ( $2 && $2 ne 'i' ) {
            if ( $2 eq 's' ) {
                $ms += $n * $MICROSEC_IN_SEC;
            }
            elsif ( $2 eq 'm' ) {
                $ms += $n * $MICROSEC_IN_MIN;
            }
            elsif ( $2 eq 'h' ) {
                $ms += $n * $MICROSEC_IN_HOUR;
            }
            elsif ( $2 eq 'd' ) {
                $ms += $n * $MICROSEC_IN_DAY;
            }
        }
        else {
            $ms += $n;
        }
    }
    return $ms;
}

# ------------------------------------------------------------------------------
1;
