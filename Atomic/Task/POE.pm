package Atomic::Task::POE;

# ------------------------------------------------------------------------------
use Modern::Perl;

use lib q{..};
use Atomic::TaskPool;
use base qw/Atomic::TaskPool/;

use AnyEvent::Sleep;
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
            'inline_states' => {
                '_start' => sub {
                    print "Session ", $_[SESSION]->ID, " has started.\n";
                    $_[HEAP]->{idx} = $start;
                    $_[HEAP]->{end} = $end;
                    $_[KERNEL]->yield('next_task');
                },
                'next_task' => sub {

                    #                    say sprintf 'SID: %s, %u', $_[SESSION]->ID, $_[HEAP]->{idx};

                    #                    for ( $_[HEAP]->{idx} .. $_[HEAP]->{end} ) {

                    my $task = $tasks[ $_[HEAP]->{idx} ];

                    #                        my $task = $tasks[$_];
                    return unless $task;
                    $task->run;

                    #                    }
                    ++$_[HEAP]->{idx};
                    $_[KERNEL]->yield('next_task') if $_[HEAP]->{idx} < $_[HEAP]->{end};
                },

                #                '_stop' => sub {

                #                    say sprintf 'SID: %s, STOP', $_[SESSION]->ID;
                #                },
            }
        );
    }

    POE::Kernel->run;

=pod
    my @threads;
    for ( 0 .. $children - 1 ) {
        my $idx = $piece * $_;
        push @threads, async {

            for ( $_[0] .. $_[1] ) {
                my $task = $tasks[$_];
                last unless $task;
                $task->run;
            }
        }
        $idx, ( $idx + $piece );
    }
    $_->join() for @threads;
=cut

    return;
}

# ------------------------------------------------------------------------------
1;
__END__


=for comment
    
use POE;

                for (1..10) {
                        POE::Session->create(
                                'inline_states' => {
                                        '_start'    => sub {
                                                print "Session ", $_[SESSION]->ID, " has started.\n";
                                                $_[HEAP]->{'count'} = 0;
                                                $_[KERNEL]->yield('increment');
                                        },
                                        'increment' => sub {
                                                print "Session ", $_[SESSION]->ID, " counted to", ++$_[HEAP]->{'count'}, ".\n";
                                                $_[KERNEL]->yield('increment') if $_[HEAP]->{'count'} < 10;
                                        },
                                        '_stop'     => sub {
                                                print "Session ", $_[SESSION]->ID, " has stopped.\n";
                                        },
                                }
                        );
                }

                POE::Kernel->run;
    
    
=cut
