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

