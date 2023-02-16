package Atomic::Task::Pool;

# ------------------------------------------------------------------------------
#use forks;
#use forks::shared;
use Modern::Perl;
use Array::Utils qw/intersect/;
use Sys::Info;
#use threads::shared qw/share/;

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
    $self->{params}->{pieces}
        = POSIX::ceil( scalar( keys %{ $self->{tasks} } ) / $self->{params}->{children} );
#    share %{$_} for values %{ $self->{tasks} };
#    bless( $_, (ref $_) . '::Shared' ) for values %{ $self->{tasks} };
    return $self;
}

# ------------------------------------------------------------------------------
sub _check_resources_lock
{
    my ( $self, $newtask ) = @_;

#printf "[[%s]]\n", $newtask->id;

    if ( !$newtask->{params}->{mutex} || $newtask->{params}->{commit_lock} ) {

=for comment
    Проверка на пересечение по ресурсам если в задаче лочится только коммит, или не лочится ничего
=cut

        my $error;
        while ( my ( $tid, $task ) = each %{ $self->{tasks} } ) {
            next if $tid eq $newtask->id;
            my @rc = intersect( @{ $newtask->{resources} }, @{ $task->{resources} } );
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
