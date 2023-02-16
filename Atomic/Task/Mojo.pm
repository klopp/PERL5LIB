package Atomic::Task::Mojo;

# ------------------------------------------------------------------------------
use Modern::Perl;

use lib q{..};
use Atomic::TaskPool;
use base qw/Atomic::TaskPool/;

use Mojo::IOLoop;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $tasks, $params ) = @_;
    return $class->SUPER::new( $tasks, $params );
}

# ------------------------------------------------------------------------------
sub run
{
    my ( $self, $children ) = @_;

    $children ||= $self->{params}->{children};
    my ( $worker, @tasks ) = ( undef, values %{ $self->{tasks} } );

    $worker = sub {
        while (@tasks) {
            my $task = shift @tasks;
            $task and $task->run;
        }
        Mojo::IOLoop->stop;
    };
    $worker->() for 1 .. $children;
    Mojo::IOLoop->start;
    return;
}

# ------------------------------------------------------------------------------
1;
__END__
