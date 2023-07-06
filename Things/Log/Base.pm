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
    'ERR'       => $LOG_ERROR,
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
    $self->{root} ||= 'log';
    $self->{log_}->{exe} = $PROGRAM_NAME;
    @ARGV and $self->{log_}->{exe} .= q{ } . join q{ }, @ARGV;

    my $package = ref $self;
    for my $method ( sort { length $a <=> length $b } keys %METHODS ) {
        my $level = $METHODS{$method};
        $self->{methods_}->{$level} = $method;
        $method = lc $method;
        no strict 'refs';
        *{"$package\::$method"} = sub {
            my $this = shift;
            my ( $sec, $microsec ) = gettimeofday;
            if ( $this->{queue_} ) {
                $this->{queue_}->enqueue( [ $level, $sec, $microsec, @_ ] );
            }
            else {
                $this->_log( $level, $sec, $microsec, @_ );
            }
            return $this;
        }
    }

    return $self;
}

# ------------------------------------------------------------------------------
sub nb
{
    if ( !$self->{queue_} ) {
        $self->{queue_} = Thread::Queue->new;
        threads->create(
            sub {
                while ( defined( my $args = $self->{queue_}->dequeue ) ) {
                    $self->_log( @{$args} );
                }
            },
        )->detach;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _log
{
    my ( $level, $sec, $microsec, $fmt, @data ) = @args;
    if ( $level <= $self->{level} ) {
        my $msg = $self->_msg( $level, $sec, $microsec, $fmt, @data );
        $msg and $self->plog($msg);
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    if ( $self->{queue_} ) {
        $self->{queue_}->end;
        while ( $self->{queue_}->pending ) {
            usleep 1_000;
        }
        threads->exit;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _msg
{
    my ( $level, $sec, $microsec, $fmt, @data ) = @args;

    my $msg = trim( sprintf $fmt, @data );
    if ( $msg =~ /^[';#]/sm ) {
        $self->{comments} or return;
        $msg =~ s/^[';#]+//sm;
    }
    my $method = $self->{methods_}->{$level};
    $self->{log_}->{pid}               = $PID;
    $self->{log_}->{level}             = $method;
    $self->{log_}->{ $self->{root} } = $msg;
    if ( $self->{microsec} ) {
        $self->{log_}->{tstamp} = $sec * 1_000_000 + $microsec;
        return sprintf '%s.%-6u %-6u %s %s', ( strftime '%F %X', localtime $sec ), $microsec, $PID, $method, $msg;
    }
    $self->{log_}->{tstamp} = $sec;
    return sprintf '%s %-6u %s %s', ( strftime '%F %X', localtime $sec ), $PID, $method, $msg;
}

# ------------------------------------------------------------------------------
sub plog
{
    return Carp::confess sprintf 'Method %s() must be overloaded.', ( caller 0 )[3];
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

