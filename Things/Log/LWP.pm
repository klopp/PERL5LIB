package Things::Log::LWP;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use HTTP::Request;
use LWP::UserAgent;
use URI::Encode qw/uri_encode/;

# use URI::Escape qw/uri_escape/;

use Things::Trim;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( !$self->{method} ) {
        $self->{error} = 'No required "method" parameter.';
        return $self;
    }
    $self->{method} = uc $self->{method};
    if ( $self->{method} ne 'POST' && $self->{method} ne 'GET' ) {
        $self->{error} = 'Invalid "method" parameter (no POST or GET).';
        return $self;
    }
    if ( !$self->{url} ) {
        $self->{error} = 'No required "url" parameter.';
        return $self;
    }
    $self->{prefix} ||= 'log';

    $self->{ua} = LWP::UserAgent->new;
    while ( my ( $key, $value ) = each %{ $self->{params} } ) {
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
sub _get
{
    my ($msg) = @args;

    my $url = $self->{url};
    if ( -1 == index $url, q{?} ) {
        $url .= q{?} . $msg;
    }
    else {
        $url .= q{&} . $msg;
    }
    my $rq = HTTP::Request->new( GET => $url );
    my $rc = $self->{ua}->request($rq);

    #if (!$response->is_success) {
    #die $response->status_line;
    #}
    return $self;
}

# ------------------------------------------------------------------------------
sub _post
{
    my ($msg) = @args;

    my $rq = HTTP::Request->new( POST => $self->{url} );
    $rq->content_type('application/x-www-form-urlencoded');
    $rq->content($msg);
    my $rc = $self->{ua}->request($rq);

    #if (!$response->is_success) {
    #die $response->status_line;
    #}
    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    my ($msg) = @args;
    if ( $self->{split} ) {
        $msg = sprintf 'tstamp=%s&pid=%s&level=%s&msg=%s', uri_encode( $self->{log}->{tstamp} ),
            uri_encode( $self->{log}->{pid} ), uri_encode( $self->{log}->{level} ), uri_encode( $self->{log}->{msg} );
    }
    else {
        $msg = $self->{prefix} . q{=} . uri_encode($msg);
    }
    if ( $self->{method} eq 'POST' ) {
        return $self->_post($msg);
    }
    return $self->_get($msg);
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::LWP->new( method => 'get', url => 'http://localhost/' );
    # prefix:   data prefix (default: "log=...") 
    # OR
    # split:    BOOL (send tstamp=, pid=, level=, msg=)
    # params:   LWP::UserAgent methods with data
    # headers:  HTTP::Headers pairs
=cut

# ------------------------------------------------------------------------------
