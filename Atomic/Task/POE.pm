package Atomic::Task::POE;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use POE;

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

    my @tasks = values %{ $self->{tasks} };
    my $piece = POSIX::ceil( scalar @tasks / $children );

    for ( 0 .. $children - 1 ) {

        my $start = $piece * $_;
        my $end   = $start + $piece;

        POE::Session->create(
            inline_states => {
                _start => sub {
                    $_[HEAP]->{idx} = $start;
                    $_[HEAP]->{end} = $end;
                    $_[KERNEL]->yield('next_task');
                },
                next_task => sub {
                    my $task = $tasks[ $_[HEAP]->{idx} ];
                    return unless $task;
                    $task->run;
                    ++$_[HEAP]->{idx};
                    $_[KERNEL]->yield('next_task') if $_[HEAP]->{idx} < $_[HEAP]->{end};
                },
                _stop => sub {
                },
            }
        );
    }

    POE::Kernel->run;

    return;
}

# ------------------------------------------------------------------------------
1;
__END__

