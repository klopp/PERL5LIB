package Things::Autoload;

use strict;
use warnings;
use self;

# ------------------------------------------------------------------------------
our $AUTOLOAD;
our $VERSION = 'v2.0';

#------------------------------------------------------------------------------
sub get_object
{
    return $self;
}

#------------------------------------------------------------------------------
sub AUTOLOAD
{
    ( my $method = $AUTOLOAD ) =~ s/.*:://gsm;
    my $object = $self->get_object;
    {
        no strict 'refs';
        *{$AUTOLOAD} = sub { shift; return $object->$method(@_); };
    }
    return $object->$method(@args);
}

# ------------------------------------------------------------------------------
1;
__END__
