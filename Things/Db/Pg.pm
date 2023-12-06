package Things::Db::Pg;

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
    my ( $host, $base, $user, $password, $dbargs ) = @args;
    $dbargs = $self->check_dbargs($dbargs);
    return
        bless { db => DBI->connect( sprintf( 'dbi:Pg:dbname=%s;host=%s', $base, $host ), $user, $password, $dbargs ) },
        $self;
}

# ------------------------------------------------------------------------------
sub upsert
{
    my ( $table, $key, $data ) = @args;

    my ( @fields, @values, @set, @placeholders );

    while ( my ( $k, $v ) = each %{$data} ) {
        push @fields,       $k;
        push @values,       $v;
        push @set,          sprintf '"%s" = ?', $k;
        push @placeholders, q{?};
    }

    my $q = sprintf q{
            INSERT INTO "%s" ("%s") 
                VALUES (%s)
            ON CONFLICT("%s") DO UPDATE 
                SET %s 
    }, $table, join( '","', @fields ), join( q{,}, @placeholders ), $key, join( q{,}, @set );

    my $sth = $self->prepare($q);
    return $sth ? $sth->execute( @values, @values ) : $sth;
}

# ------------------------------------------------------------------------------
1;
__END__
