package Things::Db::Sqlite;

use strict;
use warnings;
use self;

use DBI;
use Module::Filename;

use Things::Db::Base;
use base qw/Things::Db::Base/;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $dbfile, @dbargs ) = @args;
    return bless { db => DBI->connect( sprintf( 'dbi:SQLite:dbname=%s', $dbfile ), '', '', @dbargs ) }, $self;
}

# ------------------------------------------------------------------------------
1;
__END__
