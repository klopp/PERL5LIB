package Mutex::Base;

# ------------------------------------------------------------------------------
use Try::Catch;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub lock
{
    my ($self) = @_;
    my $error;
    try {
        $self->{mutex}->lock;
    }
    catch {
        $error = $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub unlock
{
    my ($self) = @_;
    try {
        $self->{mutex}->unlock;
    };
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    return $self->unlock;
}

# ------------------------------------------------------------------------------
1;
__END__
