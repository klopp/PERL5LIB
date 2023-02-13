package Things::Sqlite;

use StdUse;

use Const::Fast;
use Module::Filename;

use DBI;

use Things::Db;
use base qw/Things::Db/;

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
1;
__END__
