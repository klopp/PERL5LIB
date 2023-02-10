package Things::Sqlite;

use StdUse;

use Const::Fast;
use Module::Filename;

use DBI;

use Things::Autoload;
use base qw/Things::Autoload/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
const my $DB_FILE => Module::Filename->new->filename(__PACKAGE__)->dir . '/../data/things.db';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $file, @dbargs ) = @_;
    my $dbfile = $file || $DB_FILE;
    return bless { db => DBI->connect( sprintf( 'dbi:SQLite:dbname=%s', $dbfile ), '', '', @dbargs ) }, $class;
}

# ------------------------------------------------------------------------------
sub get_object
{
    my ($self) = @_;
    return $self->{db};
}

# ------------------------------------------------------------------------------
sub select_field
{
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->selectrow_hashref( $select, @attrs );
    $rc or return;
    return $rc->{$field};
}

# ------------------------------------------------------------------------------
sub select_fields
{
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->selectall_arrayref( $select, { Slice => {} }, @attrs );
    $rc or return;
    my @fields = map { $_->{$field} } @{$rc};
    return wantarray ? @fields : \@fields;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    return $self->{db}->disconnect;
}

# ------------------------------------------------------------------------------
1;
__END__
