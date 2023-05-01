package Things::Instance;

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
            reason => 'open',
            errno  => $ERRNO,
            msg    => sprintf 'Can not open lockfile "%s" (%s)',
            $lockfile, $ERRNO
        };
    }
    binmode $fh;
    sysread $fh, $port, 1024;
    $port =~ s/^\s*(\d*).*/$1/gsm;
    if ( $port !~ /^\d+$/sm ) {
        $port = empty_port();
    }
    if ( !( $lock = try_lock_socket($port) ) ) {
        close $fh;
        return {
            port   => $port,
            reason => 'lock',
            errno  => $ERRNO,
            msg    => sprintf 'Can not lock process on port %u (%s)',
            $port, $ERRNO
        };
    }
    $port = "$port\n";
    if (   !flock( $fh, LOCK_EX )
        || !truncate( $fh, 0 )
        || !sysseek( $fh, 0, SEEK_SET )
        || !syswrite( $fh, $port, length $port ) )
    {
        close $fh;
        return {
            reason => 'write',
            errno  => $ERRNO,
            msg    => sprintf 'Can not write lockfile "%s" (%s)',
            $lockfile, $ERRNO
        };
    }
    close $fh;
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_and_carp
{
    my ($lockfile) = @_;
    my $lock = lock_instance($lockfile);
    $lock->{errno} and Carp::carp $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_and_cluck
{
    my ($lockfile) = @_;
    my $lock = lock_instance($lockfile);
    $lock->{errno} and Carp::cluck $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_croak
{
    my ($lockfile) = @_;
    my $lock = lock_instance($lockfile);
    $lock->{errno} and Carp::croak $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_confess
{
    my ($lockfile) = @_;
    my $lock = lock_instance($lockfile);
    $lock->{errno} and Carp::confess $lock->{msg};
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
    use Things::Instance qw/lock_or_confess/;
    lock_or_confess($LOCKFILE);
    #
    # OR [, OR...]
    #
    use Things::Instance;
    my $lock = lock_instance($LOCKFILE);
    $lock->{errno} and Carp::croak $lock->{msg};
    #
    # OR
    #
    use Things::Instance;
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
