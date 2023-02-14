package Things::PeriodicCall;

# ------------------------------------------------------------------------------
use StdUse;

=for comment
    WIP!
=cut

# ------------------------------------------------------------------------------
use Const::Fast;
use Things qw/:const/;
use Mutex;
use POSIX qw/mktime/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $opt ) = @_;

    if (   !defined $opt->{INTERVAL}
        || $opt->{INTERVAL} !~ /^\d+$/sm
        || $opt->{INTERVAL} < $SEC_IN_MIN
        || $opt->{INTERVAL} >= $SEC_IN_DAY )
    {
        Carp::croak('Invalid INTERVAL parameter.');
    }

    if ( !defined $opt->{EXEC} || ref $opt->{EXEC} ne 'CODE' ) {
        Carp::croak('Invalid EXEC parameter.');
    }

    if ( defined $opt->{LOG} && ref $opt->{LOG} ne 'CODE' ) {
        Carp::croak('Invalid LOG parameter.');
    }

    if ( !defined $opt->{HOUR_START} && !defined $opt->{HOUR_END} ) {
        $opt->{HOUR_START} = $opt->{HOUR_END} = 0;
    }

    $opt->{HOUR_START} //= 1;
    $opt->{HOUR_END}   //= $HOUR_IN_DAY;
    if (   $opt->{HOUR_START} !~ /^\d+$/sm
        || $opt->{HOUR_START} < 0
        || $opt->{HOUR_START} > $HOUR_IN_DAY )
    {
        Carp::croak('Invalid HOUR_START parameter.');
    }
    if (   $opt->{HOUR_END} !~ /^\d+$/sm
        || $opt->{HOUR_END} < 0
        || $opt->{HOUR_END} > $HOUR_IN_DAY )
    {
        Carp::croak('Invalid HOUR_END parameter.');
    }
    if ( $opt->{HOUR_START} > $opt->{HOUR_END} ) {
        Carp::croak( 'HOUR_END (%u) before HOUR_START (%u).', $opt->{HOUR_END}, $opt->{HOUR_START} );
    }

    my $self = {
        opt      => $opt,
        MUTEX    => Mutex->new,
        ITER_MAX => int( $SEC_IN_DAY / $opt->{INTERVAL} ),
    };

    return bless $self, $class;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;

    local $SIG{ALRM} = sub { $self->_on_timer };

    #    local $SIG{USR1} = \&$self->_event_request;
    #    local $SIG{USR2} = \&$self->_event_request;
    #    local $SIG{HUP}  = \&$self->_event_request;
    local $SIG{TERM} = sub { $self->_bye };
    local $SIG{INT}  = sub { $self->_bye };

    my $tnow = time;
    if ( !$self->_event_now($tnow) ) {
        $tnow = $self->_get_next_event( $tnow - $self->{opt}->{INTERVAL} );
        $self->_print_next_event($tnow);
    }
    alarm 1;
    while (1) { sleep $self->{opt}->{INTERVAL} }
    return $self->_bye();
}

# ------------------------------------------------------------------------------
sub _bye
{
    my ($self) = @_;

    $self->{MUTEX}->lock;
    exit;
}

# ------------------------------------------------------------------------------
sub _event_now
{
    my ( $self, $event ) = @_;

    my $now = time;
    return $event <= $now if $self->{opt}->{HOUR_START} == $self->{opt}->{HOUR_END};

    my $hour = ( localtime $now )[2] || $HOUR_IN_DAY;
    return $hour >= $self->{opt}->{HOUR_START} && $hour < $self->{opt}->{HOUR_END} && $event <= $now;
}

# ------------------------------------------------------------------------------
sub _get_next_event
{
    my ( $self, $next ) = @_;

    return $next + $self->{opt}->{INTERVAL} if $self->{opt}->{HOUR_START} == $self->{opt}->{HOUR_END};

    my ( $iter, $hour, $mday, $mon, $year ) = (0);
    do {
        $next += $self->{opt}->{INTERVAL};
        ( undef, undef, $hour, $mday, $mon, $year ) = localtime $next;
        $hour ||= $HOUR_IN_DAY;

        if ( ++$iter > $self->{ITER_MAX} ) {
            $self->{opt}->{LOG}->( $self->{opt}, q{!}, 'Can not find next event time, set to period start.' )
                if $self->{opt}->{LOG};
            $next = mktime( 0, 0, $self->{opt}->{HOUR_START}, $mday + 1, $mon, $year );
            last;
        }
    } while ( $hour >= $self->{opt}->{HOUR_END} || $hour < $self->{opt}->{HOUR_START} );

    return $next;
}

# ------------------------------------------------------------------------------
sub _print_next_event
{
    my ( $self, $next ) = @_;

    if ( $self->{opt}->{LOG} ) {
        my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime $next;
        $self->{opt}->{LOG}->(
            $self->{opt}, q{.},           'Next event: %u %s %u, at %02u:%02u:%02u.',
            $mday,        $MONTHS3[$mon], $year + $YEAR_OFFSET,
            $hour,        $min,           $sec
        );
    }
    return $next;
}

# ------------------------------------------------------------------------------
sub _on_timer
{
    my ($self) = @_;

    CORE::state $next = time;
    if ( $self->_event_now($next) ) {

        $self->{MUTEX}->enter(
            sub {
                $self->{opt}->{EXEC}->( $self->{opt} );
            }
        );
        $next = $self->_get_next_event($next);
        $self->_print_next_event($next);
    }
    return alarm $SEC_IN_MIN;
}

# ------------------------------------------------------------------------------

1;
