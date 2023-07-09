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
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( !$self->{method} ) {
        $self->{error} = 'No required "method" parameter.';
        return $self;
    }
    $self->{http_method_} = lc $self->{method};
    delete $self->{method};

    if ( $self->{http_method_} ne 'post' && $self->{http_method_} ne 'get' ) {
        $self->{error} = 'Invalid "method" parameter (no POST or GET).';
        return $self;
    }
    if ( !$self->{url} ) {
        $self->{error} = 'No required "url" parameter.';
    }
    $self->{url_} = $self->{url};
    delete $self->{url};
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    my $query = 'message=' . uri_encode($msg);
    if ( $self->{use_fields_} ) {
        my $log_data = $self->{log_};
        $log_data->{trace} and $log_data->{trace} = join "\n", @{ $log_data->{trace} };
        my @values;
        push @values, "$_=" . uri_encode $log_data->{$_} for keys %{$log_data};
        $query = join q{&}, @values;
    }
    if ( $self->{http_method_} eq 'get' ) {
        my $url = $self->{url_};
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
    return $self;
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
