package Things::Instance::LockSock;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
use Lock::Socket qw/try_lock_socket/;
use Net::EmptyPort qw/empty_port/;

use Things::Instance::LockBase;
use base qw/Things::Instance::LockBase/;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub _try_lock
{
    if ( $self->{data} !~ /^\d+$/sm || $self->{data} >= 0xFFFF ) {
        $self->{data} = empty_port();
    }

    my $lockh;
    if ( !( $lockh = try_lock_socket( $self->{data} ) ) ) {
        close $self->{fh};
        $self->{errno} = $ERRNO;
        $self->{error} = sprintf 'Can not lock process on port %u (%s)', $self->{data}, $ERRNO,;
    }
    else {
        $self->{lockh} = $lockh;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

