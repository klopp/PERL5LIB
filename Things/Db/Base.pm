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
# change `XYZ` to DB-specific quoting for identifiers
# ------------------------------------------------------------------------------
sub qi
{
    my ($q) = @args;
    for my $id ( $q =~ /`(\w+)`/smg ) {
        $q =~ s/`$id`/$self->{db}->quote_identifier($id)/sme;
    }
    return $q;
}

# ------------------------------------------------------------------------------
sub get_object
{
    return $self->{db};
}

# ------------------------------------------------------------------------------
sub select_field
{
    my ( $select, $field, @bind ) = @args;
    my $rc = $self->selectrow_hashref( $self->qi($select), {}, @bind );
    $rc or return;
    return $rc->{$field};
}

# ------------------------------------------------------------------------------
sub select_fields
{
    my ( $select, $field, @bind ) = @args;
    my $rc = $self->selectall_arrayref( $self->qi($select), { Slice => {} }, @bind );
    $rc or return;
    my @fields = map { $_->{$field} } @{$rc};
    return wantarray ? @fields : \@fields;
}

# ------------------------------------------------------------------------------
# table (string),
# key name (string),
# data to insert {
#       name => value, ...
#    }
# ------------------------------------------------------------------------------
sub upsert
{
    my ( $table, $key, $data ) = @args;

    my ( @fields, @values, @placeholders );

    while ( my ( $k, $v ) = each %{$data} ) {
        push @fields,       $k;
        push @values,       $v;
        push @placeholders, q{?};
    }
    my $q = sprintf q{
            REPLACE INTO `%s` (`%s`) VALUES(%s)
        }, $table, join( '`,`', @fields ), join( q{,}, @placeholders );

    my $sth = $self->prepare( $self->qi($q) );
    return $sth ? $sth->execute(@values) : $sth;
}

# ------------------------------------------------------------------------------
sub cget
{
    my ( $name, $table ) = @args;
    $table ||= $CONFIG_TABLE;
    return $self->select_field( sprintf( 'SELECT `value` FROM `%s` WHERE name = ?', $table ), 'value', undef, $name );
}

# ------------------------------------------------------------------------------
sub cset
{
    my ( $name, $value, $table ) = @args;
    $table ||= $CONFIG_TABLE;
    return $self->upsert( $table, 'name', { name => $name, value => $value } );
}

# ------------------------------------------------------------------------------
sub cjget
{
    my ( $name, $table ) = @args;
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
    my ( $name, $value, $table ) = @args;
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
    $self->{db} and $self->{db}->disconnect;
}

# ------------------------------------------------------------------------------
1;
__END__
