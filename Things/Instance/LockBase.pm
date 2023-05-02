package Things::Instance::LockBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use English qw/-no_match_vars/;
use File::Basename qw/basename/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;
use Try::Tiny;

use Things::Xargs;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

# ------------------------------------------------------------------------------
sub lock
{
    my ( $self, @args ) = @_;

    my $opt;
    try {
        $opt = xargs(@args);
    }
    catch {
        $self->{error} = $_;
    };
    $self->{error} and return $self;

    if ( !$opt->{file} ) {
        my $name = basename($PROGRAM_NAME);
        $name =~ s/^(.+)[.][^.]+$/$1/gsm;
        $opt->{file} = sprintf '/var/lock/%s.lock', $name;
    }

    if ( !sysopen $self->{fh}, $opt->{file}, O_RDWR | O_CREAT ) {
        return {
            reason => 'open',
            errno  => $ERRNO,
            msg    => sprintf 'Can not open lockfile "%s" (%s)',
            $opt->{file}, $ERRNO,
        };
    }
    binmode $self->{fh};
    sysread $self->{fh}, $self->{data}, 1024;
    $self->{data} =~ s/^\s*(\d*).*/$1/gsm;

    my $lock = $self->_try_lock($opt);
    $lock->{errno} and return $lock;

    my $rc;
    if ( $opt->{noclose} ) {
        $rc = flock( $self->{fh}, LOCK_SH ) && truncate( $self->{fh}, 0 ) && sysseek( $self->{fh}, 0, SEEK_SET );
    }
    else {
        $rc
            = flock( $self->{fh}, LOCK_SH )
            && truncate( $self->{fh}, 0 )
            && sysseek( $self->{fh}, 0, SEEK_SET )
            && syswrite( $self->{fh}, $self->{data} . "\n" );
    }
    if ( !$rc ) {
        close $self->{fh};
        return {
            reason => 'write',
            errno  => $ERRNO,
            msg    => sprintf 'Can not write lockfile "%s" (%s)',
            $opt->{file}, $ERRNO,
        };
    }
    $lock->{fh} = $self->{fh};
    $opt->{noclose} or close $self->{fh};
    return $lock;
}

# ------------------------------------------------------------------------------
sub _try_lock
{
    Carp::croak 'Method %s() must be overloaded', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub lock_and_carp
{
    my ( $self, @args ) = @_;
    my $lock = $self->lock(@args);
    $lock->{errno} && Carp::carp $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_and_cluck
{
    my ( $self, @args ) = @_;
    my $lock = $self->lock(@args);
    $lock->{errno} && Carp::cluck $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_croak
{
    my ( $self, @args ) = @_;
    my $lock = $self->lock(@args);
    $lock->{errno} && Carp::croak $lock->{msg};
    return $lock;
}

# ------------------------------------------------------------------------------
sub lock_or_confess
{
    my ( $self, @args ) = @_;
    my $lock = $self->lock(@args);
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
