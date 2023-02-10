package Things::Db;

use StdUse;

use Const::Fast;
use Module::Filename;

use DBI;

our $VERSION = 'v1.0';
our $AUTOLOAD;

# ------------------------------------------------------------------------------
const my $DB_FILE => Module::Filename->new->filename(__PACKAGE__)->dir . '/../data/things.db';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @args ) = @_;
    return bless { db => DBI->connect( sprintf( 'dbi:SQLite:dbname=%s', $DB_FILE ), '', '', @args ) }, $class;
}

# ------------------------------------------------------------------------------
sub select_field
{
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->{db}->selectrow_hashref($select, @attrs);
    return $rc->{$field};
}

# ------------------------------------------------------------------------------
sub select_fields
{
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->{db}->selectall_arrayref($select, { Slice => {} }, @attrs);
    my @fields = map { $_->{$field} } @{$rc};
    return wantarray ? @fields : \@fields;
}

# ------------------------------------------------------------------------------
sub AUTOLOAD
{
    my ( $self, @args ) = @_;
    $AUTOLOAD =~ s/^(.+::)+//gsm;
    return $self->{db}->$AUTOLOAD(@args);
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
