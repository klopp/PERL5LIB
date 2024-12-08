package Things::Const;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT_OK = qw/
    $YEAR_OFFSET
    $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
    $MICROSEC_IN_SEC $MILLISEC_IN_SEC $MICROSEC_IN_HOUR $MICROSEC_IN_MIN $MICROSEC_IN_DAY
    @MONTHS3 %MONTHS3
    $ARRAY $HASH $SCALAR $GLOB $CODE
    $GTK_MOUSE_LBTN $GTK_MOUSE_MBTN $GTK_MOUSE_RBTN
    $NUM_10 $NUM_100 $NUM_1000 NUM_1024 $MINUS_ONE $NUM_3
    $NUM_4 $NUM_8 $NUM_16 $NUM_32 $NUM_64
    $NUM_128 $NUM_256 $NUM_512 
    $TWO_TO_2 $TWO_TO_3 $TWO_TO_4 $TWO_TO_5 $TWO_TO_6 $TWO_TO_7 $TWO_TO_8
    $TWO_TO_9 $TWO_TO_10 $TWO_TO_11 $TWO_TO_12 $TWO_TO_13 $TWO_TO_14 $TWO_TO_15 $TWO_TO_16
    /;
our %EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
    'gtk' => [
        qw/
            $GTK_MOUSE_LBTN $GTK_MOUSE_MBTN $GTK_MOUSE_RBTN
            /,
    ],
    'types' => [
        qw/
            $ARRAY $HASH $SCALAR $GLOB $CODE
            /,
    ],
    'num' => [
        qw/
            $NUM_10 $NUM_100 $NUM_1000 NUM_1024 $MINUS_ONE $NUM_3
            $NUM_4 $NUM_8 $NUM_16 $NUM_32 $NUM_64
            $NUM_128 $NUM_256 $NUM_512 
            /,
    ],
    'two' => [
        qw/ $TWO_TO_2 $TWO_TO_3 $TWO_TO_4 $TWO_TO_5 $TWO_TO_6 $TWO_TO_7 $TWO_TO_8
            $TWO_TO_9 $TWO_TO_10 $TWO_TO_11 $TWO_TO_12 $TWO_TO_13 $TWO_TO_14 $TWO_TO_15 $TWO_TO_16
            /,
    ],
    'dt' => [
        qw/
            $YEAR_OFFSET
            $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
            $MILLISEC_IN_SEC $MICROSEC_IN_SEC $MICROSEC_IN_HOUR $MICROSEC_IN_MIN $MICROSEC_IN_DAY
            @MONTHS3 %MONTHS3
            /,
    ],
);
$EXPORT_TAGS{datetime} = \@{ $EXPORT_TAGS{dt} };
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use Const::Fast;
const our $ARRAY            => 'ARRAY';
const our $HASH             => 'HASH';
const our $SCALAR           => 'SCALAR';
const our $GLOB             => 'GLOB';
const our $CODE             => 'CODE';
const our $MINUS_ONE        => -1;
const our $NUM_3            => 3;
const our $NUM_4            => 4;
const our $NUM_8            => 8;
const our $NUM_10           => 10;
const our $NUM_16           => 16;
const our $NUM_32           => 32;
const our $NUM_64           => 64;
const our $NUM_100          => 100;
const our $NUM_128          => 128;
const our $NUM_256          => 256;
const our $NUM_512          => 512;
const our $NUM_1000         => 1_000;
const our $NUM_1024         => 1_024;
const our $TWO_TO_2         => 2**2;
const our $TWO_TO_3         => 2**3;
const our $TWO_TO_4         => 2**4;
const our $TWO_TO_5         => 2**5;
const our $TWO_TO_6         => 2**6;
const our $TWO_TO_7         => 2**7;
const our $TWO_TO_8         => 2**8;
const our $TWO_TO_9         => 2**9;
const our $TWO_TO_10        => 2**10;
const our $TWO_TO_11        => 2**11;
const our $TWO_TO_12        => 2**12;
const our $TWO_TO_13        => 2**13;
const our $TWO_TO_14        => 2**14;
const our $TWO_TO_15        => 2**15;
const our $TWO_TO_16        => 2**16;
const our $YEAR_OFFSET      => 1_900;
const our $MICROSEC_IN_SEC  => 1_000_000;
const our $MILLISEC_IN_SEC  => 1_000;
const our $SEC_IN_MIN       => 60;
const our $MICROSEC_IN_MIN  => $SEC_IN_MIN * $MICROSEC_IN_SEC;
const our $HOUR_IN_DAY      => 24;
const our $MIN_IN_HOUR      => 60;
const our $MIN_IN_DAY       => $MIN_IN_HOUR * $HOUR_IN_DAY;
const our $SEC_IN_HOUR      => $SEC_IN_MIN * $MIN_IN_HOUR;
const our $MICROSEC_IN_HOUR => $SEC_IN_MIN * $MIN_IN_HOUR * $MICROSEC_IN_SEC;
const our $MICROSEC_IN_DAY  => $SEC_IN_HOUR * $HOUR_IN_DAY * $MICROSEC_IN_SEC;
const our $SEC_IN_DAY       => $SEC_IN_HOUR * $HOUR_IN_DAY;
const our @MONTHS3          => qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
const our %MONTHS3          => map { $_ => $MONTHS3[$_] } 0 .. @MONTHS3 - 1;
const our $GTK_MOUSE_LBTN   => 1;
const our $GTK_MOUSE_MBTN   => 2;
const our $GTK_MOUSE_RBTN   => 3;

# ------------------------------------------------------------------------------
1;
