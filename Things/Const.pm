package Things::Const;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT_OK = qw/
    $YEAR_OFFSET
    $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
    @MONTHS3 %MONTHS3
    $ARRAY $HASH $SCALAR $GLOB $CODE
    /;
our %EXPORT_TAGS = (
    'all'   => \@EXPORT_OK,
    'types' => [
        qw/
            $ARRAY $HASH $SCALAR $GLOB $CODE
            /,
    ],
    'dt' => [
        qw/
            $YEAR_OFFSET
            $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
            @MONTHS3 %MONTHS3
            /,
    ],
);
$EXPORT_TAGS{datetime} = \@{ $EXPORT_TAGS{dt} };
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use Const::Fast;
const our $ARRAY       => 'ARRAY';
const our $HASH        => 'HASH';
const our $SCALAR      => 'SCALAR';
const our $GLOB        => 'GLOB';
const our $CODE        => 'CODE';
const our $YEAR_OFFSET => 1900;
const our $SEC_IN_MIN  => 60;
const our $HOUR_IN_DAY => 24;
const our $MIN_IN_HOUR => 60;
const our $MIN_IN_DAY  => $MIN_IN_HOUR * $HOUR_IN_DAY;
const our $SEC_IN_HOUR => $SEC_IN_MIN * $MIN_IN_HOUR;
const our $SEC_IN_DAY  => $SEC_IN_HOUR * $HOUR_IN_DAY;
const our @MONTHS3     => qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
const our %MONTHS3     => map { $_ => $MONTHS3[$_] } 0 .. @MONTHS3 - 1;

# ------------------------------------------------------------------------------
1;
