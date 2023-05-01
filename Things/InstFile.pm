package Things::InstFile;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT      = qw/lock_instance/;
our @EXPORT_OK   = qw/lock_instance lock_or_croak lock_or_confess lock_and_cluck lock_and_carp/;
our %EXPORT_TAGS = (
    'all'  => \@EXPORT_OK,
    'die'  => qw/lock_or_croak lock_or_confess/,
    'warn' => qw/lock_and_cluck lock_and_carp/,
);
our $VERSION = 'v1.1';

use English qw/-no_match_vars/;
use Errno qw/:POSIX/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;

# ------------------------------------------------------------------------------
sub lock_instance
{
    my ( $lockfile, $noclose ) = @_;

    my ( $pid, $fh );
    if ( !sysopen $fh, $lockfile, O_RDWR | O_CREAT ) {
        return {
            reason => 'open',
            errno  => $ERRNO,
            msg    => sprintf 'Can not open lockfile "%s" (%s)',
            $lockfile, $ERRNO,
        };
    }
    binmode $fh;
    sysread $fh, $pid, 1024;
    $pid =~ s/^\s*(\d*).*/$1/gsm;
    if ( $pid =~ /^\d+$/sm and kill 0 => $pid ) {
        close $fh;
        $ERRNO = EBUSY;
        return {
            pid    => $pid,
            reason => 'lock',
            errno  => $ERRNO,
            msg    => sprintf 'Active instance (PID: %u) found',
            $pid,
        };
    }

    my $rc;
    if ($noclose) {
        $rc = flock( $fh, LOCK_SH ) && truncate( $fh, 0 ) && sysseek( $fh, 0, SEEK_SET );
    }
    else {
        $rc = flock( $fh, LOCK_SH ) && truncate( $fh, 0 ) && sysseek( $fh, 0, SEEK_SET ) && syswrite( $fh, "$PID\n" );
    }
    if ( !$rc ) {
        close $fh;
        return {
            reason => 'write',
            errno  => $ERRNO,
            msg    => sprintf 'Can not write lockfile "%s" (%s)',
            $lockfile, $ERRNO,
        };
    }
    $noclose and return { fh => $fh, };
    close $fh;
    return {};
}

# ------------------------------------------------------------------------------
sub lock_and_carp
{
    my ( $lockfile, $noclose ) = @_;
    my $lock = lock_instance( $lockfile, $noclose );
    $lock->{errno} && Carp::carp $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_and_cluck
{
    my ( $lockfile, $noclose ) = @_;
    my $lock = lock_instance( $lockfile, $noclose );
    $lock->{errno} && Carp::cluck $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_croak
{
    my ( $lockfile, $noclose ) = @_;
    my $lock = lock_instance( $lockfile, $noclose );
    $lock->{errno} && Carp::croak $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_confess
{
    my ( $lockfile, $noclose ) = @_;
    my $lock = lock_instance( $lockfile, $noclose );
    $lock->{errno} && Carp::confess $lock->{msg};
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
