package Things;

use Exporter;
use base qw/Exporter/;

our @EXPORT_OK = qw/
    trim set_bool set_true set_false xget
    $YEAR_OFFSET
    $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
    @MONTHS3
    /;
our %EXPORT_TAGS = (
    'all'   => \@EXPORT_OK,
    'func'  => [qw/trim set_bool set_true set_false xget/],
    'bool'  => [qw/set_bool set_true set_false/],
    'const' => [
        qw/
            $YEAR_OFFSET
            $SEC_IN_MIN $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_HOUR $SEC_IN_DAY
            @MONTHS3
            /
    ],
);

# ------------------------------------------------------------------------------
use Const::Fast;
use Scalar::Util qw/readonly/;

const my $YEAR_OFFSET => 1900;
const my $SEC_IN_MIN  => 60;
const my $HOUR_IN_DAY => 24;
const my $MIN_IN_HOUR => 60;
const my $MIN_IN_DAY  => $MIN_IN_HOUR * $HOUR_IN_DAY;
const my $SEC_IN_HOUR => $SEC_IN_MIN * $MIN_IN_HOUR;
const my $SEC_IN_DAY  => $SEC_IN_HOUR * $HOUR_IN_DAY;
const my @MONTHS3     => qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

# ------------------------------------------------------------------------------
sub trim
{
    for (@_) {

        # trim( ' ... ' ) умник, да?
        readonly($_) and next;

        if ( ref $_ eq 'ARRAY' ) {
            trim( @{$_} );
        }
        elsif ( ref $_ eq 'HASH' ) {
            while ( my ($key) = each %{$_} ) {
                trim( $_->{$key} );
            }
        }
        elsif ( !ref $_ ) {
            s/^\s+|\s+$//gsm;
        }
    }
    return wantarray ? @_ : $_[0];
}

# ------------------------------------------------------------------------------
sub set_true
{
    $_[1] = 1;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
sub set_false
{
    $_[1] = undef;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
sub set_bool
{

=for comment
    * выставить:
        $flag = set_bool(\$flag);
        $flag = set_bool(\$flag, 1);
    * сбросить:
        $flag = set_bool(\$flag, undef);
        $flag = set_bool(\$flag, 0);
    Использование в blessed:
        sub set_flag {
            my $self = shift;
            return set_bool(\$self->{flag}, @_ ? shift : 1);
        }
=cut

    if ( @_ < 1 ) {
        Carp::cluck sprintf 'No target argument at %s()', ( caller 0 )[3];
        return;
    }
    if ( ref $_[0] ne 'SCALAR' ) {
        Carp::cluck sprintf 'Target argument must be SCALAR REF at %s()', ( caller 0 )[3];
        return;
    }
    ${ $_[0] } = ( @_ == 1 || $_[1] ) ? 1 : undef;
    return ${ $_[0] };
}

# ------------------------------------------------------------------------------
sub xget
{
    my ( $src, $path ) = @_;

=for comment
    my $data = { a => [ 0, 1, 2, { b => 'c' } ] };
    #
    # "3" может быть индексом ARRAY или ключом HASH:
    my $rc = xget( $data, '/a/3/b' );
    #
    # ИЛИ
    #
    # "3" - только индекс (проверяем что ref $src->{a} eq 'ARRAY'):
    my $rc = xget( $data, '/a/[3]/b' );
    # В обоих случаях получили 'c'.
=cut    

    my @parts  = grep {$_} trim( split( '/', $path ) );
    my $cursor = $src;

    for (@parts) {
        if (/^\[(\d+)\]$/) {
            return if ref $cursor ne 'ARRAY';
            $cursor = $cursor->[$1];
        }
        elsif ( ref $cursor eq 'HASH' ) {
            $cursor = $cursor->{$_};
        }
        elsif ( ref $cursor eq 'ARRAY' ) {
            return unless /^(\d+)$/;
            $cursor = $cursor->[$1];
        }
        else {
            return;
        }
    }
    return $cursor;
}

# ------------------------------------------------------------------------------
1;
__END__

