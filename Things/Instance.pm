package Things::Instance;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use English qw/-no_match_vars/;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/lock_instance/;
our $VERSION = 'v1.1';

use English qw/-no_match_vars/;
use Fcntl qw/:DEFAULT :flock/;
use Lock::Socket qw/try_lock_socket/;
use Net::EmptyPort qw/empty_port/;

# ------------------------------------------------------------------------------
sub lock_instance
{
    my ($lockfile) = @_;

    my ( $lock, $port, $fh );
    if ( !sysopen $fh, $lockfile, O_RDWR | O_CREAT ) {
        return { reason => 'open', errno => $ERRNO, };
    }
    sysread $fh, $port, 64;
    $port and $port =~ s/^\s+|\s+$//gsm;
    if ( !$port || $port !~ /^\d+$/sm ) {
        $port = empty_port();
    }
    if ( !( $lock = try_lock_socket($port) ) ) {
        close $fh;
        return { port => $port, reason => 'lock', errno => $ERRNO, };
    }
    if ( !flock( $fh, LOCK_EX ) || !truncate( $fh, 0 ) || !syswrite( $fh, $port, length $port ) ) {
        close $fh;
        return { reason => 'write', errno => $ERRNO, };
    }
    close $fh;
    return $lock;
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Carp qw/confess/;
    use Const::Fast;
    use English qw/-no_match_vars/;
    use Things::Instance;

    const my $LOCKFILE => '/var/lock/' . $PROGRAM_NAME . '.lock';

    my $lock = lock_instance($LOCKFILE);
    if ( $lock->{errno} ) {
        if ( $lock->{reason} eq 'open' ) {
            confess sprintf 'Open file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'lock' ) {
            confess sprintf 'Lock process on port %u (%s)!', $lock->{port}, $lock->{errno};
        }
        elsif ( $lock->{reason} eq 'write' ) {
            confess sprintf 'Write file "%s" (%s)!', $LOCKFILE, $lock->{errno};
        }
        else {
            confess sprintf 'Unknown error reason (%s)!', $lock->{errno};
        }
        exit 1;
    }
    #
    # do something
    #
    undef $lock;
=cut

# ------------------------------------------------------------------------------
