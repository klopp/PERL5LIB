package Things::Format;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT    = qw/seconds2text/;
our @EXPORT_OK = (@EXPORT);

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub seconds2text
{
    my ($sec) = @_;

    $sec //= 0;
    #---------------------------------------------------------------------------
    sub mkstring
    {
        my ( $TIME_VALUE, $UNIT ) = @_;
        my $OUT;

        if    ( $TIME_VALUE == 0 ) { $OUT = q{}; }
        elsif ( $TIME_VALUE == 1 ) { $OUT = '1 ' . $UNIT . ', '; }
        else                       { $OUT = $TIME_VALUE . q{ } . $UNIT . 's, '; }
        return $OUT;
    }

    #---------------------------------------------------------------------------
    my $STRING;

    my $SECOND = $sec % 60;
    my $MINUTE = ( $sec / 60 ) % 60;
    my $HOUR   = ( $sec / ( 60 * 60 ) ) % 24;
    my $DAY    = int( $sec / ( 24 * 60 * 60 ) ) % 7;
    my $WEEK   = int( $sec / ( 24 * 60 * 60 * 7 ) );

    # Build the output string
    $STRING = mkstring( $WEEK, 'week' );
    $STRING .= mkstring( $DAY,    'day' );
    $STRING .= mkstring( $HOUR,   'hour' );
    $STRING .= mkstring( $MINUTE, 'minute' );
    $STRING .= mkstring( $SECOND, 'second' );

    # Remove the trailing comma and space
    chop $STRING;
    chop $STRING;

    $STRING = 'less than 1 second' unless $STRING;

    return $STRING;
}

# ------------------------------------------------------------------------------
__END__
