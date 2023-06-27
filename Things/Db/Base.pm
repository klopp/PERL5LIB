package Things::Db::Base;

use strict;
use warnings;
use self;

use Const::Fast;
use JSON::XS qw/decode_json encode_json/;
use Try::Catch;

use Things::Autoload;
use base qw/Things::Autoload/;

const my $CONFIG_TABLE => 'config';
our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub new
{
    return bless { db => undef }, $self;
}

# ------------------------------------------------------------------------------
sub get_object
{
    $self->{db} or return Carp::confess sprintf 'Error: {db} field is empty in "%s()".', ( caller 1 )[3];
    return $self->{db};
}

# ------------------------------------------------------------------------------
sub select_field
{
    my ( $select, $field, $attrs, @bind ) = @args;
    my $rc = $self->selectrow_hashref( $select, $attrs || {}, @bind );
    $rc or return;
    return $rc->{$field};
}

# ------------------------------------------------------------------------------
sub select_fields
{
    my ( $select, $field, @attrs ) = @args;
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

    my ( $table, $key, $data ) = @args;

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
    my ( $name ) = @args;
    return $self->select_field( sprintf( 'SELECT value FROM %s WHERE name = ?', $CONFIG_TABLE ), 'value', undef,
        $name );
}

# ------------------------------------------------------------------------------
sub cset
{
    my ( $name, $value ) = @args;
    return $self->upsert( $CONFIG_TABLE, 'name', { name => $name, value => $value } );
}

# ------------------------------------------------------------------------------
sub cjget
{
    my ( $name ) = @args;
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
    my ( $name, $value ) = @args;
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
    return $self->{db}->disconnect;
}

# ------------------------------------------------------------------------------
1;
__END__
