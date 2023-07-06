package Things::Log::HttpAsync;

# ------------------------------------------------------------------------------
# Bad, bad, bad!
# Do not use this module in real code. Never.
# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use HTTP::Async;
use Time::HiRes qw/usleep/;

use Things::Log::HttpBase;
use base qw/Things::Log::HttpBase/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
#   params => [ key => value, ... ]
#       HTTP::Async parameters
#       see https://metacpan.org/pod/HTTP::Async#new
#   headers => [ key => value, ... ]
#       HTTP headers
#       https://metacpan.org/pod/HTTP::Headers
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    $self->{async_} = HTTP::Async->new( %{ $self->{params} } );
    return $self;
}

# ------------------------------------------------------------------------------
sub url_get
{
    my ($url) = @args;
    $self->{async_}->add( HTTP::Request->new( GET => $url, $self->{headers} ) );
    return $self;
}

# ------------------------------------------------------------------------------
sub url_post
{
    my ($content) = @args;
    $self->{async_}->add( HTTP::Request->new( POST => $self->{url_}, $self->{headers}, $content ) );
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    while ( $self->{async_}->total_count ) {
        usleep 1_000;
    }
    return $self->SUPER::DESTROY;
}

# ------------------------------------------------------------------------------
1;
__END__
