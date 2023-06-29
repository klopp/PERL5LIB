package Things::Log::File;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;
use utf8::all;

use English qw/-no_match_vars/;
use Fcntl qw/:flock/;
use IO::Interactive qw/is_interactive/;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( !$self->{file} ) {
        $self->{error} = 'No required "file" parameter.';
        return $self;
    }
    if ( $self->{file} eq q{-} ) {
        $self->{fh} = *STDOUT;
    }
    else {
        if ( !open $self->{fh}, '>>', $self->{file} ) {
            $self->{error} = sprintf 'Can not open file "%s" (%s)', $self->{file}, $ERRNO;
            return $self;
        }
    }
    $self->{fh}->autoflush(1);

    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    return $self unless $self->{fh};

    my ($msg) = @args;

    flock $self->{fh}, LOCK_EX;
    $self->{fh}->print( $msg . "\n" );
    flock $self->{fh}, LOCK_UN;
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    if ( $self->{fh} ) {
        is_interactive( $self->{fh} ) or close $self->{fh};
    }
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::File->new( file => '/var/log/my.log', comments => 1 );

=cut

# ------------------------------------------------------------------------------
