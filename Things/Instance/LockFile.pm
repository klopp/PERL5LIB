package Things::Instance::LockFile;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use English qw/-no_match_vars/;
use Errno qw/:POSIX/;
use Things::Instance::LockBase;
use base qw/Things::Instance::LockBase/;

our $VERSION = 'v1.1';

# ------------------------------------------------------------------------------
sub _try_lock
{
    my ( $self, $opt ) = @_;

    if ( $self->{data} =~ /^\d+$/sm and kill 0 => $self->{data} ) {
        close $self->{fh};
        $ERRNO = EBUSY;
        return {
            pid    => $self->{data},
            reason => 'lock',
            errno  => $ERRNO,
            msg    => sprintf 'Active instance (PID: %u) found',
            $self->{data},
        };
    }
    $self->{data} = $PID;
    return {};
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
    use Things::InstFile qw/lock_or_confess/;
    lock_or_confess($LOCKFILE);
    #
    # OR [, OR ...]
    #
    use Things::InstFile;
    my $lock = lock_instance($LOCKFILE);
    $lock->{errno} and Carp::croak $lock->{msg};
    close $lock->{fh};
    #
    # OR [, OR ...]
    #
    use Things::InstFile;
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
    close $lock->{fh};
    #
    # do something
    #
    undef $lock;
=cut

# ------------------------------------------------------------------------------
