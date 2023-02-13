package Things::Db;

use StdUse;

use Const::Fast;
use DBI;
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
    my $q = sprintf q{
            INSERT INTO %s (name, value) VALUES(?, ?)
                ON CONFLICT(name) DO 
            UPDATE SET value = ?
        }, $CONFIG_TABLE;
    my $sth = $self->prepare($q);
    return $sth ? $sth->execute( $name, $value, $value ) : $sth;
}

# ------------------------------------------------------------------------------
sub jget
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
sub jset
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
