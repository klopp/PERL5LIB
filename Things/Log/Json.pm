package Things::Log::Json;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Things::Log::JsonBase;
use Things::Log::File;
use base qw/Things::Log::File/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
#   json => [ method => value, ... ]
#       JSON::XS options
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    return get_json($self);
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;
    $msg = to_json( $msg, $self );
    $msg and $self->SUPER::plog($msg);
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Json->new
    (
        file => '/var/log/my.log',
        json => [ key => value, ... ]
    );

=cut

# ------------------------------------------------------------------------------
