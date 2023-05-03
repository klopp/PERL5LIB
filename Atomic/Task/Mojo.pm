package Atomic::Task::Mojo;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Mojo::IOLoop;

use Atomic::TaskPool;
use base qw/Atomic::TaskPool/;

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
