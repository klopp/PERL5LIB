package Things::Instance::LockSock;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
####use Fcntl qw/:DEFAULT :flock SEEK_SET/;
use Lock::Socket qw/try_lock_socket/;
use Net::EmptyPort qw/empty_port/;

use Things::Instance::LockBase;
use base qw/Things::Instance::LockBase/;

our $VERSION = 'v1.2';

# ------------------------------------------------------------------------------
sub _try_lock
{
    my ( $self, $opt ) = @_;

    if ( $self->{data} !~ /^\d+$/sm || $self->{data} >= 0xFFFF ) {
        $self->{data} = empty_port();
    }

    my $lockh;
    if ( !( $lockh = try_lock_socket( $self->{data} ) ) ) {
        close $self->{fh};
        return {
            port   => $self->{data},
            reason => 'lock',
            errno  => $ERRNO,
            msg    => sprintf 'Can not lock process on port %u (%s)',
            $self->{data}, $ERRNO,
        };
    }
    return $lockh;
}

# ------------------------------------------------------------------------------
1;
__END__

