package Things::Log::File;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;
use utf8::all;

use English qw/-no_match_vars/;
use Fcntl qw/:flock/;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    $self->{file} or Carp::croak 'No required "file" parameter.';
    if ( $self->{file} eq q{-} ) {
        $self->{fh} = *STDOUT;
    }
    else {
        open( $self->{fh}, '>>', $self->{file} )
            or Carp::croak sprintf 'Can not open log file "%s" (%s)', $self->{file}, $ERRNO;
    }
    $self->{fh}->autoflush(1);

    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    my ($msg) = @args;

    flock $self->{fh}, LOCK_EX;
    $self->{fh}->print($msg);
    flock $self->{fh}, LOCK_UN;
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    if ( $self->{fh} ) {
        -t $self->{fh} or close $self->{fh};
    }
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
