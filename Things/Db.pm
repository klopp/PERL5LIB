package Things::Db;

use StdUse;

use Carp qw/confess/;
use Const::Fast;
use JSON::XS qw/decode_json encode_json/;
use Try::Tiny;

use Things::Autoload;
use base qw/Things::Autoload/;

const my $CONFIG_TABLE => 'config';
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ($class) = @_;
    return bless { db => undef }, $class;
}

# ------------------------------------------------------------------------------
sub get_object
{
    my ($self) = @_;
    $self->{db} or return confess sprintf 'Error: {db} field is empty in "%s()".', ( caller 1 )[3];
    return $self->{db};
}

# ------------------------------------------------------------------------------
sub select_field
{
    my ( $self, $select, $field, $attrs, @bind ) = @_;
    my $rc = $self->selectrow_hashref( $select, $attrs || {}, @bind );
    $rc or return;
    return $rc->{$field};
}

# ------------------------------------------------------------------------------
sub select_fields
{
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->selectall_arrayref( $select, { Slice => {} }, @attrs );
    $rc or return;
    my @fields = map { $_->{$field} } @{$rc};
    return wantarray ? @fields : \@fields;
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

    my ( @fields, @values, @placeholders );

    while ( my ( $k, $v ) = each %{$data} ) {
        push @fields,       $k;
        push @values,       $v;
        push @placeholders, q{?};
    }
    my $q = sprintf q{
            REPLACE INTO `%s` (`%s`) VALUES(%s)
        }, $table, join( '`,`', @fields ), join( ',', @placeholders );

    my $sth = $self->prepare($q);
    return $sth ? $sth->execute(@values) : $sth;
}

# ------------------------------------------------------------------------------
sub cget
{
    my ( $self, $name ) = @_;
    return $self->select_field( sprintf( 'SELECT value FROM %s WHERE name = ?', $CONFIG_TABLE ), 'value', undef,
        $name );
}

# ------------------------------------------------------------------------------
sub cset
{
    my ( $self, $name, $value ) = @_;
    return $self->upsert( $CONFIG_TABLE, 'name', { name => $name, value => $value } );
}

# ------------------------------------------------------------------------------
sub cjget
{
    my ( $self, $name ) = @_;
    my $rc = $self->cget($name);
    try {
        $rc and $rc = decode_json $rc;
    }
    catch {
        undef $rc;
    };
    return $rc;
}

# ------------------------------------------------------------------------------
sub cjset
{
    my ( $self, $name, $value ) = @_;
    try {
        $value = encode_json $value;
    }
    catch {
        undef $value;
    };
    return $value ? $self->cset( $name, $value ) : $value;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    return $self->{db}->disconnect;
}

# ------------------------------------------------------------------------------
1;
__END__
