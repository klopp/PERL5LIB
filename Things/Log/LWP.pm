package Things::Log::LWP;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use LWP::UserAgent;
use URI::Encode qw/uri_encode/;

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
sub _get
{
    my ($form) = @args;

    my $query = $self->{prefix} . q{=} . $form->{ $self->{prefix} };
    if ( $self->{split} ) {
        $query
            = 'pid='
            . $form->{pid}
            . '&level='
            . $form->{level}
            . '&tstamp='
            . $form->{tstamp} . q{&}
            . $self->{prefix} . q{=}
            . $form->{ $self->{prefix} };
    }
    my $url = $self->{url};
    if ( -1 == index $url, q{?} ) {
        $url .= q{?} . $query;
    }
    else {
        $url .= q{&} . $query;
    }
    my $rc = $self->{ua}->get($url);
    $rc->is_success or $self->{error} = $rc->status_line;
    return $self;
}

# ------------------------------------------------------------------------------
sub _post
{
    my $rc = $self->{ua}->post( $self->{url}, @args );
    $rc->is_success or $self->{error} = $rc->status_line;
    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    my ($msg) = @args;

    my %form;
    if ( $self->{split} ) {
        $form{tstamp}            = uri_encode( $self->{log}->{tstamp} );
        $form{pid}               = uri_encode( $self->{log}->{pid} );
        $form{level}             = uri_encode( $self->{log}->{level} );
        $form{ $self->{prefix} } = uri_encode( $self->{log}->{ $self->{prefix} } );
    }
    else {
        $form{ $self->{prefix} } = uri_encode($msg);
    }
    if ( $self->{method} eq 'POST' ) {
        return $self->_post( \%form );
    }
    return $self->_get( \%form );
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::LWP->new( method => 'get', url => 'http://localhost/' );
    # prefix:   data prefix (default: "log=...") 
    # OR
    # split:    BOOL (if true send tstamp=, pid=, level=, log=)
    # params:   LWP::UserAgent methods with data
    # headers:  HTTP::Headers pairs
=cut

# ------------------------------------------------------------------------------
