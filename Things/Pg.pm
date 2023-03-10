package Things::Pg;

use StdUse;

use DBI;

use Things::Db;
use base qw/Things::Db/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $base, $user, $password, @dbargs ) = @_;
    return bless { db => DBI->connect( sprintf( 'dbi:Pg:dbname=%s', $base ), $user, $password, @dbargs ) }, $class;
}

# ------------------------------------------------------------------------------
sub upsert
{

=for comment
    table (string),
    key (string),
    {
        name => value, ...
    }
=cut

    my ( $self, $table, $key, $data ) = @_;

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
