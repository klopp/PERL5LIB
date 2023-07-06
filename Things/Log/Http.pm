package Things::Log::Http;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use LWP::UserAgent;
use URI::Encode qw/uri_encode/;

use Things::Log::HttpBase;
use base qw/Things::Log::HttpBase/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
#   params => [ key => value, ... ]
#       LWP::UserAgent attributes, except default_header & default_headers
#       see https://metacpan.org/pod/LWP::UserAgent#ATTRIBUTES
#   headers => [ key => value, ... ]
#       HTTP headers
#       https://metacpan.org/pod/LWP::UserAgent#default_header
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    $self->{ua} = LWP::UserAgent->new;
    while ( my ( $key, $value ) = each %{ $self->{params} } ) {

        # skip default_headers(), default_header():
        next if $key =~ /header/ism;
        if ( my $method = $self->{ua}->can($key) ) {
            $self->{ua}->$method($value);
        }
    }
    while ( my ( $key, $value ) = each %{ $self->{headers} } ) {
        $self->{ua}->default_header( $key, $value );
    }

    return $self;
}

# ------------------------------------------------------------------------------
sub url_get
{
    my ($url) = @args;
    my $rc = $self->{ua}->get($url);
    $rc->is_success or $self->{error} = $rc->status_line;
    return $self;
}

# ------------------------------------------------------------------------------
sub url_post
{
    my ($content) = @args;
    my $rc = $self->{ua}->post( $self->{url}, Content => $content );
    $rc->is_success or $self->{error} = $rc->status_line;
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::LWP->new( method => 'get', url => 'http://localhost/' );
    # log:      message prefix (default: "log=...") 
    # OR
    # split:    BOOL (if true send tstamp=, pid=, level=, message=)
    # params:   LWP::UserAgent methods with data
    # headers:  HTTP::Headers pairs
=cut

# ------------------------------------------------------------------------------
