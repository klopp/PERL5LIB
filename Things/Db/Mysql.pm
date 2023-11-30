package Things::Db::Mysql;

use strict;
use warnings;
use self;

use DBI;

use Things::Db::Base;
use base qw/Things::Db::Base/;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $host, $base, $user, $password, @dbargs ) = @args;
    return bless { db => DBI->connect( sprintf( 'dbi:mysql:host=%s;dbname=%s', $host, $base ), $user, $password, @dbargs ) },
        $self;
}

# ------------------------------------------------------------------------------
1;
__END__
