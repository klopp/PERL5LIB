package Things::Db::Sqlite;

use strict;
use warnings;
use Module::Filename;

use DBI;

use Things::Db::Base;
use base qw/Things::Db::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $file, @dbargs ) = @_;
    my $dbfile = $file;
    return bless { db => DBI->connect( sprintf( 'dbi:SQLite:dbname=%s', $dbfile ), '', '', @dbargs ) }, $class;
}

# ------------------------------------------------------------------------------
1;
__END__
