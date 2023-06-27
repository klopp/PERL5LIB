package Things::Db::Mysql;

use strict;
use warnings;
use self;

use DBI;

use Things::Db::Base;
use base qw/Things::Db::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $base, $user, $password, @dbargs ) = @args;
    return bless { db => DBI->connect( sprintf( 'dbi:mysql:dbname=%s', $base ), $user, $password, @dbargs ) },
        $self;
}

# ------------------------------------------------------------------------------
1;
__END__
