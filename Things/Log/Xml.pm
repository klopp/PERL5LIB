package Things::Log::Xml;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;
use utf8::all;

use XML::Hash::XS;

use Things::Log::File;
use base qw/Things::Log::File/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
#   xml => [ key => value, ... ]
#       XML::Hash::XS options
#       (canonical is always 1, root is 'log' by default)
#       https://metacpan.org/pod/XML::Hash::XS#OPTIONS
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    $self->{xml}->{xml_decl} = 0; 
    $self->{xml}->{canonical} = 1; 
    $self->{xml}->{root} ||= 'log'; 
    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    my ($msg) = hash2xml $self->{log}, %{$self->{xml}};
    return $self->SUPER::_print($msg);
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
