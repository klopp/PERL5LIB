package Things::Instance::LockSock;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Things::Instance::LockBase;
use base qw/Things::Instance::LockBase/;
our $VERSION = 'v1.2';

use English qw/-no_match_vars/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;
use Lock::Socket qw/try_lock_socket/;
use Net::EmptyPort qw/empty_port/;

# ------------------------------------------------------------------------------
sub _try_lock
{
    my ( $self, $opt ) = @_;

    if ( $self->{data} !~ /^\d+$/sm || $self->{data} >= 0xFFFF ) {
        $self->{data} = empty_port();
    }

    my $lock;
    if ( !( $lock = try_lock_socket( $self->{data} ) ) ) {
        close $self->{fh};
        return {
            port   => $self->{data},
            reason => 'lock',
            errno  => $ERRNO,
            msg    => sprintf 'Can not lock process on port %u (%s)',
            $self->{data}, $ERRNO,
        };
    }
    return $lock;
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    # our @EXPORT      = qw/lock_instance/;
    # our @EXPORT_OK   = qw/ lock_instance 
    #                        lock_or_croak lock_or_confess 
    #                        lock_and_cluck lock_and_carp /;
    # our %EXPORT_TAGS = (
    #    'all'  => \@EXPORT_OK,
    #    'die'  => qw/lock_or_croak lock_or_confess/,
    #    'warn' => qw/lock_and_cluck lock_and_carp/,
    # );
    #
    use Things::InstSock qw/lock_or_confess/;
    lock_or_confess($LOCKFILE);
    #
    # OR [, OR ...]
    #
    use Things::InstSock;
    my $lock = lock_instance($LOCKFILE);
    $lock->{errno} and Carp::croak $lock->{msg};
    #
    # OR [, OR ...]
    #
    use Things::InstSock;
    my $lock = lock_instance($LOCKFILE);
    if ( $lock->{errno} ) {
        if ( $lock->{reason} eq 'open' ) {
            Carp::confess sprintf 'Open file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'lock' ) {
            Carp::confess sprintf 'Lock process on port %u (%s)!', $lock->{port}, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'write' ) {
            Carp::confess sprintf 'Write file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        else {
            Carp::confess sprintf 'Unknown error reason (%s)!', $lock->{errno};
        }
        exit 1;
    }
    #
    # do something
    #
    undef $lock;
=cut

# ------------------------------------------------------------------------------
