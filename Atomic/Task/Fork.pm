package Atomic::Task::Fork;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Parallel::ForkManager;
use Sys::Info;

use lib q{..};
use Atomic::Task::Pool;
use base qw/Atomic::Task::Pool/;

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

    my $pm    = Parallel::ForkManager->new( $self->{params}->{children} );
    my @tasks = values %{ $self->{tasks} };

    for ( 1 .. $self->{params}->{children} ) {
        my @pieces = splice @tasks, 0, $self->{params}->{pieces};
        $pm->start and next;
        ( $_ and $_->run ) for @pieces;
        $pm->finish;
    }
    $pm->wait_all_children;
}

# ------------------------------------------------------------------------------
1;
__END__
