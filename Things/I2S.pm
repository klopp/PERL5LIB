package Things::I2S;

#use Exporter qw/import/;
use base qw/Exporter/;
our @EXPORT  = qw/i2s interval_to_seconds/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use lib q{.};
use Things::Const qw/:datetime/;

# ------------------------------------------------------------------------------
sub i2s
{
    goto &interval_to_seconds;
}

# ------------------------------------------------------------------------------
# PART:
#   \d+[s] - seconds, \d+[m] - minutes, \d+[h] - hours, \d+[d] - days
# IN string:
#   PART[{, }PART...]
# Example:
#   "1d, 24m, 3h, 30s"
#
# OR
#   "23:3:6:15" => 23 days, 3 hours, 6 minutes, 15 seconds
#   "3:6:15"    => 3 hours, 6 minutes, 15 seconds
#   etc
# ------------------------------------------------------------------------------
sub interval_to_seconds
{
    my ($interval) = @_;
    my $seconds = 0;
    my @parts;

    if ( $interval =~ /^(\d+[:]?)+$/gsm ) {
        @parts = split /[:]/, $interval;
        $seconds += pop @parts;
        $seconds += pop(@parts) * $SEC_IN_MIN  if @parts;
        $seconds += pop(@parts) * $SEC_IN_HOUR if @parts;
        $seconds += pop(@parts) * $SEC_IN_DAY  if @parts;
        return $seconds;
    }

    @parts = split /[,\s]+/sm, lc $interval;
    for (@parts) {
        return unless /^(\d+)([smhd]?)$/ism;
        my $n = $1;
        if ( $2 eq 'm' ) {
            $seconds += $1 * $SEC_IN_MIN;
        }
        elsif ( $2 eq 'h' ) {
            $seconds += $1 * $SEC_IN_HOUR;
        }
        elsif ( $2 eq 'd' ) {
            $seconds += $1 * $SEC_IN_DAY;
        }
        else {
            $seconds += $1;
        }
    }
    return $seconds;
}

# ------------------------------------------------------------------------------
1;
