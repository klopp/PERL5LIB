package Atomic::Task::Coro;

# ------------------------------------------------------------------------------
use Modern::Perl;

use lib q{..};
use Atomic::Task::Pool;
use base qw/Atomic::Task::Pool/;

use Coro;

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

    my @threads;
    for ( 0 .. $children - 1 ) {
        my $idx = $piece * $_;
        push @threads, async {

            for ( $_[0] .. $_[1] ) {
                say sprintf '%s => %s', @_;
                my $task = $tasks[$_];
                last unless $task;
                $task->run;
            }
        }
        $idx, ( $idx + $piece );
    }
    $_->join() for @threads;

    return;
}

# ------------------------------------------------------------------------------
1;
__END__
