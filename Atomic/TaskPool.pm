package Atomic::TaskPool;

# ------------------------------------------------------------------------------
use Modern::Perl;
use Sys::Info;

use lib q{..};
use Atomic::Task;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $tasks, $params ) = @_;

    my %data = ( params => $params, );

    my $self = bless \%data, $class;
    %{ $self->{tasks} } = map { $_->id => $_ } @{$tasks};
    $self->_check_resources_lock($_) for values %{ $self->{tasks} };
    $self->{params}->{children} ||= Sys::Info->new->device('CPU')->count;
    return $self;
}

# ------------------------------------------------------------------------------
sub _check_resources_lock
{
    my ( $self, $newtask ) = @_;

    if ( !$newtask->{params}->{mutex} || $newtask->{params}->{commit_lock} ) {

=for comment
    Проверка на пересечение по ресурсам если в задаче лочится только коммит, или не лочится ничего
=cut

        my $error;
        while ( my ( $tid, $task ) = each %{ $self->{tasks} } ) {
            next if $tid eq $newtask->id;
            my @rc = grep { exists $newtask->{resources}->{$_} } keys %{ $task->{resources} };
            if (@rc) {
                $error .= sprintf "\n  '%s'", $task->id;
                $error .= sprintf( "\n    => '%s' (%s)", $_->id, ref $_ ) for @rc;
            }
        }
        $error
            and return Carp::confess sprintf
            "Task '%s', no {mutex} or {commit_lock} is set, but other tasks work with the same resources:%s\n",
            $newtask->id, $error;
    }

    return;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;
    return Carp::confess sprintf 'Error: method "error = %s()" must be overloaded.', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
1;
__END__
