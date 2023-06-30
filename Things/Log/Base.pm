package Things::Log::Base;

# ------------------------------------------------------------------------------
use threads;
use Thread::Queue;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Const::Fast;
use English qw/-no_match_vars/;
use POSIX qw/strftime/;
use Time::HiRes qw/gettimeofday usleep/;

use Things::Trim;

const our $LOG_EMERG  => 0;
const our $LOG_ALERT  => 1;
const our $LOG_CRIT   => 2;
const our $LOG_ERROR  => 3;
const our $LOG_WARN   => 4;
const our $LOG_NOTICE => 5;
const our $LOG_INFO   => 6;
const our $LOG_DEBUG  => 7;
const our $LOG_TRACE  => 8;

const my %METHODS => (
    'EMERGENCY' => $LOG_EMERG,
    'EMERG'     => $LOG_EMERG,
    'ALERT'     => $LOG_ALERT,
    'CRITICAL'  => $LOG_CRIT,
    'CRIT'      => $LOG_CRIT,
    'ERROR'     => $LOG_ERROR,
    'ERR'       => $LOG_CRIT,
    'WARNING'   => $LOG_WARN,
    'WARN'      => $LOG_WARN,
    'NOTICE'    => $LOG_NOTICE,
    'NOT'       => $LOG_NOTICE,
    'INFO'      => $LOG_INFO,
    'INF'       => $LOG_INFO,
    'DEBUG'     => $LOG_DEBUG,
    'DBG'       => $LOG_DEBUG,
    'TRACE'     => $LOG_TRACE,
    'TRC'       => $LOG_TRACE,
);

use Exporter qw/import/;
our @EXPORT = qw/$LOG_EMERG $LOG_ALERT $LOG_CRIT $LOG_ERROR $LOG_WARN $LOG_NOTICE $LOG_INFO $LOG_DEBUG $LOG_TRACE/;

our $VERSION = 'v2.00';

# ------------------------------------------------------------------------------
#   level => [$LOG_INFO]
#       log level
#   microsec => [FALSE]
#       show microseconds in time
#   comments => [FALSE]
#       show log comments
# ------------------------------------------------------------------------------
sub new
{
    $self = bless {@args}, $self;

    if ( !$self->{level} || !exists $METHODS{ $self->{level} } ) {
        $self->{level} = $LOG_INFO;
    }
    $self->{prefix} ||= 'log';
    $self->{log}->{exe} = $PROGRAM_NAME;
    @ARGV and $self->{log}->{exe} .= q{ } . join q{ }, @ARGV;

    my $package = ref $self;
    for my $method ( sort { length $a <=> length $b } keys %METHODS ) {
        my $level = $METHODS{$method};
        $self->{methods}->{$level} = $method;
        $method = lc $method;
        no strict 'refs';
        *{"$package\::$method"} = sub {
            my $this = shift;
            if ( $this->{queue} ) {
                $this->{queue}->enqueue( { level => $level, args => \@_ } );
            }
            else {
                $this->_log( $level, @_ );
            }
            return $this;
        }
    }

    return $self;
}

# ------------------------------------------------------------------------------
sub nb
{
    if ( !$self->{queue} ) {
        $self->{queue} = Thread::Queue->new;
        threads->create(
            sub {
                while ( defined( my $data = $self->{queue}->dequeue ) ) {
                    $self->_log( $data->{level}, @{ $data->{args} } );
                }
            },
        )->detach;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _log
{
    my ( $level, $fmt, @data ) = @args;
    if ( $level <= $self->{level} ) {
        my $msg = $self->_msg( $level, $fmt, @data );
        $msg and $self->_print($msg);
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    if ( $self->{queue} ) {
        $self->{queue}->end;
        while ( $self->{queue}->pending ) {
            usleep 1_000;
        }
        threads->exit;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _t
{
    # $self => seconds
    return strftime '%F %X', localtime $self;
}

# ------------------------------------------------------------------------------
sub _msg
{
    my ( $level, $fmt, @data ) = @args;

    my $msg = trim( sprintf $fmt, @data );
    if ( $msg =~ /^[';#]/sm ) {
        $self->{comments} or return;
        $msg =~ s/^[';#]+//sm;
    }
    my ( $sec, $microsec ) = gettimeofday;
    my $method = $self->{methods}->{$level};
    $self->{log}->{pid}               = $PID;
    $self->{log}->{level}             = $method;
    $self->{log}->{ $self->{prefix} } = $msg;
    if ( $self->{microsec} ) {
        $self->{log}->{tstamp} = $sec * 1_000_000 + $microsec;
        return sprintf '%s.%-6u %-6u %s %s', _t($sec), $microsec, $PID, $method, $msg;
    }
    $self->{log}->{tstamp} = $sec;
    return sprintf '%s %-6u %s %s', _t($sec), $PID, $method, $msg;
}

# ------------------------------------------------------------------------------
sub _print
{
    return Carp::croak sprintf 'Method %s() must be overloaded.', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::XXX->new(
        microsec => 1, 
        level => $LOG_INFO, 
        comments => 1 
    );

=cut

# ------------------------------------------------------------------------------

