package Things::Instance::LockBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use English qw/-no_match_vars/;
use Errno qw/:POSIX/;
use File::Basename qw/basename/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;

use Things::Xargs;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub lock
{
    my ( $self, $opt ) = selfopt(@_);
    if ( $self->{error} ) {
        $ERRNO = EINVAL;
        return {
            reason => 'options',
            errno  => $ERRNO,
            msg    => $ERRNO,
        };
    }

    $self->{file} = $opt->{file};
    if ( !$self->{file} ) {
        my $name = basename($PROGRAM_NAME);
        $name =~ s/^(.+)[.][^.]+$/$1/gsm;
        $self->{file} = sprintf '/var/lock/%s.lock', $name;
    }

    if ( !sysopen $self->{fh}, $self->{file}, O_RDWR | O_CREAT ) {
        return {
            reason => 'open',
            errno  => $ERRNO,
            msg    => sprintf 'Can not open lockfile "%s" (%s)',
            $self->{file}, $ERRNO,
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
            $self->{file}, $ERRNO,
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
 
    use Things::Instance::LockSock;
    my $locker = Things::Instance::LockSock->new;
    my $lockh = $locker->lock;
    $lockh->{errno} and Carp::confess $lockh->{msg};
    #
    # do something
    #
    undef $lock;

    use Things::Instance::LockFile;
    my $locker = Things::Instance::LockFile->new;
    my $lockh = $locker->lock;
    $lockh->{errno} and Carp::confess $lockh->{msg};
    #
    # do something
    #
    close $lock->{fh};
    undef $lock;
=cut

# ------------------------------------------------------------------------------
