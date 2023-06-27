package Things::Instance::LockFile;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use English qw/-no_match_vars/;
use Errno qw/:POSIX/;
use Exporter qw/import/;

use Things::Instance::LockBase;
use base qw/Things::Instance::LockBase/;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub _try_lock
{
    if ( $self->{data} =~ /^\d+$/sm and kill 0 => $self->{data} ) {
        close $self->{fh};
        $ERRNO         = EBUSY;
        $self->{errno} = $ERRNO;
        $self->{error} = sprintf 'Active instance (PID: %u) found', $self->{data};
    }
    else {
        $self->{data} = $PID;
    }
    return {};
}

# ------------------------------------------------------------------------------
1;
__END__

