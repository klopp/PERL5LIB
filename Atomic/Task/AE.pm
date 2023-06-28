package Atomic::Task::AE;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use AnyEvent;

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
    my ( $cv, @tasks ) = ( AnyEvent->condvar, values %{ $self->{tasks} } );

    for ( 1 .. $children ) {
        $cv->begin;
        while (@tasks) {
            my $task = shift @tasks;
            $task and $task->run;
        }
        $cv->end;
    }
    $cv->recv;
    return;
}

# ------------------------------------------------------------------------------
1;
__END__
