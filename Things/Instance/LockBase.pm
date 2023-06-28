package Things::Instance::LockBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use English qw/-no_match_vars/;
use Errno qw/:POSIX/;
use File::Basename qw/basename/;
use Fcntl qw/:DEFAULT :flock SEEK_SET/;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $file, $noclose ) = @args;

    my %data = ( file => $file, noclose => $noclose );
    if ( !$data{file} ) {
        my $name = basename($PROGRAM_NAME);
        $name =~ s/^(.+)[.][^.]+$/$1/gsm;
        $data{file} = sprintf '/var/lock/%s.lock', $name;
    }
    return bless \%data, $self;
}

# ------------------------------------------------------------------------------
sub lock
{
    $self->{error} and return $self;

    if ( !sysopen $self->{fh}, $self->{file}, O_RDWR | O_CREAT ) {
        return {
            errno => $ERRNO,
            error => sprintf 'Can not open lockfile "%s" (%s)',
            $self->{file}, $ERRNO,
        };
    }
    binmode $self->{fh};
    sysread $self->{fh}, $self->{data}, 1024;
    $self->{data} =~ s/^\s*(\d*).*/$1/gsm;

    $self->_try_lock();
    $self->{errno} and return $self;

    my $rc;
    if ( $self->{noclose} ) {
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
            errno => $ERRNO,
            error => sprintf 'Can not write lockfile "%s" (%s)',
            $self->{file}, $ERRNO,
        };
    }
    if ( !$self->{noclose} ) {
        close $self->{fh};
        delete $self->{fh};
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _try_lock
{
    return Carp::croak sprintf 'Method %s() must be overloaded', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub lock_and_carp
{
    $self->lock;
    $self->{error} && Carp::carp $self->{error};
    return $self;
}

# ------------------------------------------------------------------------------
sub lock_and_cluck
{
    $self->lock;
    $self->{error} && Carp::cluck $self->{error};
    return $self;
}

# ------------------------------------------------------------------------------
sub lock_or_croak
{
    $self->lock;
    $self->{error} && Carp::croak $self->{error};
    return $self;
}

# ------------------------------------------------------------------------------
sub lock_or_confess
{
    $self->lock;
    $self->{error} && Carp::confess $self->{error};
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Things::Instance::LockSock;
    my $locker = Things::Instance::LockSock->new( '/run/myinstance.lock' );
    $locker->{error} and Carp::confess $locker->{error};
    $locker->lock;
    $locker->{error} and Carp::confess $locker->{error};

=cut

# ------------------------------------------------------------------------------
