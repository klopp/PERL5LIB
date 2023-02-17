package Atomic::Task::POE;

# ------------------------------------------------------------------------------
use Modern::Perl;

use lib q{..};
use Atomic::TaskPool;
use base qw/Atomic::TaskPool/;

use POE;

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
                    print "Session ", $_[SESSION]->ID, " has started.\n";
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

