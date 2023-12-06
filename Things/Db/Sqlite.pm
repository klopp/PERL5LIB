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
    my ( $dbfile, $dbargs ) = @args;

    $dbargs = $self->check_dbargs($dbargs);
    return bless { db => DBI->connect( sprintf( 'dbi:SQLite:dbname=%s', $dbfile ), undef, undef, $dbargs ) },
        $self;
}

# ------------------------------------------------------------------------------
1;
__END__
