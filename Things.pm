package Things;

use Exporter qw/import/;
use base qw/Exporter/;

our @EXPORT_OK = qw/
    trim set_bool set_true set_false TRUE FALSE xget
    ip2long long2ip
    random_line random_ua
    $YEAR_OFFSET
    $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_DAY $SEC_IN_HOUR $SEC_IN_MIN
    @MONTHS3 %MONTHS3
    /;
our %EXPORT_TAGS = (
    'all'   => \@EXPORT_OK,
    'func'  => [qw/trim set_bool set_true set_false xget random_line random_ua/],
    'net '  => [qw/ip2long long2ip/],
    'bool'  => [qw/set_bool set_true set_false TRUE FALSE/],
    'const' => [
        qw/
            $YEAR_OFFSET
            $SEC_IN_MIN $HOUR_IN_DAY $MIN_IN_HOUR $MIN_IN_DAY $SEC_IN_HOUR $SEC_IN_DAY
            @MONTHS3 %MONTHS3
            /
    ],
);

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use Const::Fast;
use Module::Filename;
use Scalar::Util qw/readonly/;
use Socket qw/inet_aton inet_ntoa/;

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
const my $DATA_DIR => Module::Filename->new->filename(__PACKAGE__)->dir . '/data/';

# ------------------------------------------------------------------------------
BEGIN {
}

# ------------------------------------------------------------------------------
sub trim
{
    CORE::state $TRIM_RX = qr{^\s+|\s+$};

    for (@_) {

        # trim( ' ... ' ) умник, да?
        readonly($_) and next;

        if ( ref $_ eq 'ARRAY' ) {
            $_ =~ s/$TRIM_RX//gsm for @{$_};
        }
        elsif ( ref $_ eq 'HASH' ) {
            while ( my ($key) = each %{$_} ) {
                $_->{$key} =~ s/$TRIM_RX//gsm;
            }
        }
        elsif ( !ref $_ ) {
            $_ =~ s/$TRIM_RX//gsm;
        }
    }
    return wantarray ? @_ : $_[0];
}

# ------------------------------------------------------------------------------
sub TRUE  {1}
sub FALSE {0}

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
sub ip2long
{
    my ($ip) = @_;
    return unpack( 'l*', pack( 'l*', unpack( 'N*', inet_aton($ip) ) ) );
}

# ------------------------------------------------------------------------------
sub long2ip
{
    my ($ip) = @_;
    return inet_ntoa( pack( 'N*', $ip ) );
}

# ------------------------------------------------------------------------------
sub random_line
{
    my ( $filename, $noempty ) = @_;

    open my $fh, '<', $filename or Carp::confess sprintf 'can not open file "%s"', $filename;
    my $filesize = -s $filename;
    seek( $fh, int( rand $filesize ), 0 );
    <$fh>;
    seek( $fh, 0, 0 ) if eof $fh;
    $line = <$fh>;
    trim($line);
    while ($noempty) {
        last if $line;
        $line = <$fh>;
        trim($line);
        seek( $fh, 0, 0 ) if eof $fh;
    }
    close $fh;
    return $line;
}

# ------------------------------------------------------------------------------
sub random_ua
{
    return trim( random_line( $DATA_DIR . 'ua.list', 1 ) );
}

# ------------------------------------------------------------------------------
#sub parse_bool {
#    $_[0] = ( $_[0] && $_[0] !~ /^0|no|false|none$/i ) ? 1 : 0;
#    return $_[0];
#}

# ------------------------------------------------------------------------------
1;
__END__

