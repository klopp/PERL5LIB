package Things::Mysql;

use StdUse;

use DBI;

use Things::Db;
use base qw/Things::Db/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $base, $user, $password, @dbargs ) = @_;
    return bless { db => DBI->connect( sprintf( 'dbi:mysql:dbname=%s', $base ), $user, $password, @dbargs ) },
        $class;
}

# ------------------------------------------------------------------------------
1;
__END__
