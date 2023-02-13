package Things::Db;

use StdUse;

use DBI;

use Things::Autoload;
use base qw/Things::Autoload/;

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
    my ( $self, $select, $field, @attrs ) = @_;
    my $rc = $self->selectrow_hashref( $select, @attrs );
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
sub DESTROY
{
    my ($self) = @_;
    return $self->{db}->disconnect;
}

# ------------------------------------------------------------------------------
1;
__END__
