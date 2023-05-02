package Things::Db::Mysql;

use strict;
use warnings;
use DBI;

use Things::Db::Base;
use base qw/Things::Db::Base/;

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
