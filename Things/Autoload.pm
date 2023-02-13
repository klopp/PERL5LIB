package Things::Autoload;

use strict;
use warnings;

# ------------------------------------------------------------------------------
our $AUTOLOAD;
our $VERSION = 'v1.0';

#------------------------------------------------------------------------------
sub get_object
{
    my ($self) = @_;
    return $self;
}

#------------------------------------------------------------------------------
sub AUTOLOAD
{
    my $self = shift;

    ( my $method = $AUTOLOAD ) =~ s/.*:://gsm;
    my $object = $self->get_object;
    {
        no strict 'refs';
        *{$AUTOLOAD} = sub { shift; return $object->$method(@_); };
    }
    return $object->$method(@_);
}

# ------------------------------------------------------------------------------
1;
__END__
