package Things::Log::HttpBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use URI::Encode qw/uri_encode/;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
#   url => URL
#       URL to send log
#   method => POST or GET (nocase)
#       URL to send log
#   root => [STRING]
#       parameter with log data name, default 'log'
#   split => [FALSE]
#       if TRUE log data will be splitted:
#           message=message
#           tstamp=seconds OR microseconds
#           level=LOG_LEVEL
#           pid=PID
#           exe=$PROGRAM_NAME @ARGV
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( !$self->{method} ) {
        $self->{error} = 'No required "method" parameter.';
        return $self;
    }
    $self->{http_method_} = lc $self->{method};
    if ( $self->{http_method_} ne 'post' && $self->{http_method_} ne 'get' ) {
        $self->{error} = 'Invalid "method" parameter (no POST or GET).';
        return $self;
    }
    if ( !$self->{url} ) {
        $self->{error} = 'No required "url" parameter.';
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    my $query = $self->{root} . q{=} . uri_encode($msg);
    if ( $self->{split} ) {
        $query
            = 'pid='
            . uri_encode( $self->{log_}->{pid} ) . '&exe='
            . uri_encode( $self->{log_}->{exe} )
            . '&level='
            . uri_encode( $self->{log_}->{level} )
            . '&tstamp='
            . uri_encode( $self->{log_}->{tstamp} ) . q{&}
            . $self->{root} . q{=}
            . uri_encode( $self->{log_}->{ $self->{root} } );
    }
    if ( $self->{http_method_} eq 'get' ) {
        my $url = $self->{url};
        if ( -1 == index $url, q{?} ) {
            $url .= q{?} . $query;
        }
        else {
            $url .= q{&} . $query;
        }
        $self->url_get($url);
    }
    else {
        $self->url_post($query);
    }
}

# ------------------------------------------------------------------------------
sub url_get
{
    return Carp::confess sprintf 'Method %s() must be overloaded.', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub url_post
{
    return Carp::confess sprintf 'Method %s() must be overloaded.', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
1;
__END__
