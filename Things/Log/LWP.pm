package Things::Log::LWP;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use HTTP::Request;
use LWP::UserAgent;
use URI::Encode qw/uri_encode/;

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
    while ( my ( $key, $value ) = each %{ $self->{param} } ) {
        if ( $self->{ua}->can($key) ) {
        }
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
    $msg = $self->{prefix} . q{=} . uri_encode(trim($msg));
    if ( $self->{method} eq 'POST' ) {
        return $self->_post($msg);
    }
    return $self->_get($msg);
}

# ------------------------------------------------------------------------------

=for comment

use LWP::UserAgent;
$ua = LWP::UserAgent->new;
 
my $req = HTTP::Request->new(
    POST => 'https://rt.cpan.org/Public/Dist/Display.html');
$req->content_type('application/x-www-form-urlencoded');
$req->content('Status=Active&Name=libwww-perl');
 
my $res = $ua->request($req);

use LWP::UserAgent;
$ua = LWP::UserAgent->new;
$ua->agent("$0/0.1 " . $ua->agent);
# $ua->agent("Mozilla/8.0") # pretend we are very capable browser
 
$req = HTTP::Request->new(
   GET => 'http://search.cpan.org/dist/libwww-perl/');
$req->header('Accept' => 'text/html');
 
# send request
$res = $ua->request($req);

=cut

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::LWP->new( comments => 1 );  
    # STDERR redirect:
    # die    => $logger->emergency() + die
    # warn   => $logger->warn()
    # STDERR => $logger->notice()
=cut

# ------------------------------------------------------------------------------
