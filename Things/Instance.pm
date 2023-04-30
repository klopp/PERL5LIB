package Things::Instance;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use English qw/-no_match_vars/;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/lock_instance/;
our $VERSION = 'v1.0';

use Const::Fast;
use English qw/-no_match_vars/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;
use Lock::Socket qw/try_lock_socket/;
use Net::EmptyPort qw/empty_port/;

# ------------------------------------------------------------------------------
sub lock_instance
{
    my ($lockfile) = @_;
    my ( $lock, $port, $fh );

    if ( !sysopen $fh, $lockfile, O_RDWR | O_CREAT ) {
        return {
            errno => $ERRNO,
            emsg  => sprintf 'Error writing lock file "%s" (%s)!',
            $lockfile, $ERRNO,
        };
    }
    $fh->autoflush(1);
    sysread $fh, $port, 64;
    trim($port);
    if ( !$port || $port !~ /^\d+$/sm ) {
        $port = empty_port();
    }
    if ( !( $lock = try_lock_socket($port) ) ) {
        close $fh;
        return {
            errno => $ERRNO,
            emsg  => sprintf 'Application already locked on port %u!',
            $port,
        };
    }
    if ( !flock $fh, LOCK_EX ) {
        close $fh;
        return {
            errno => $ERRNO,
            emsg  => sprintf 'Error locking file "%s" (%s)!',
            $lockfile, $ERRNO,
        };
    }
    sysseek $fh, 0, SEEK_SET;
    syswrite $fh, $port, length $port;
    close $fh;
    return $lock;
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Things::Instance;
    my $rc = lock_instance( "/var/lock/$PROGRAM_NAME.lock" );
    if( $rc->{errno} ) 
    {
        die $rc->{emsg};
    }
    # do something
    undef $rc;

=cut

# ------------------------------------------------------------------------------
