package Things::Log::Xml;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

#use XML::Hash::XS;

use Things::Log::XmlBase;
use Things::Log::File;
use base qw/Things::Log::File/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
#   xml => [ key => value, ... ]
#       XML::Hash::XS options
#       (canonical is always 1, root is $self->{root} by default)
#       https://metacpan.org/pod/XML::Hash::XS#OPTIONS
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    return get_xml($self);
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;
    $msg = to_xml( $msg, $self );
    return $self->SUPER::plog($msg);
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Xml->new
    (
        file => '/var/log/my.log',
        xml => [ key => value, ... ]
    );

=cut

# ------------------------------------------------------------------------------
