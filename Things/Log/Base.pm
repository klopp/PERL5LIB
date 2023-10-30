package Things::Log::Base;

# ------------------------------------------------------------------------------
use threads;
use threads::shared;
use Thread::Queue;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Const::Fast;
use English qw/-no_match_vars/;
use POSIX qw/strftime/;
use Sys::Hostname;
use Time::HiRes qw/gettimeofday usleep/;

use Things::Bool;
use Things::Const qw/:types/;
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

const my %FIELDS  => qw/tstamp 1 pid 1 level 1 exe 1 host 1 trace 1/;
const my $FMT_DEF => '%Z %-6p %L %@';

use parent qw/Exporter/;
our @EXPORT = qw/$LOG_EMERG $LOG_ALERT $LOG_CRIT $LOG_ERROR $LOG_WARN $LOG_NOTICE $LOG_INFO $LOG_DEBUG $LOG_TRACE/;

our $VERSION = 'v2.10';

# ------------------------------------------------------------------------------
my @NB_LOGGERS;

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub import
{
    if ( $self ne __PACKAGE__ ) {
        no strict 'refs';
        @{ $self . '::EXPORT' } = @EXPORT;
    }
    @_ = ( $self, @args );
    goto &Exporter::import;
}

# ------------------------------------------------------------------------------
sub _level2asc
{
    my ( $level ) = @_;
    while( my ($asc, $num) = each %METHODS ) {
        $num == $level and return $asc;
    }
    return 'INFO';
}

# ------------------------------------------------------------------------------
#   level => [$LOG_INFO]
#       log level
#   format => [$FMT_DEF]
#       log line format
#   comments => [FALSE]
#       show log comments
# ------------------------------------------------------------------------------
sub new
{
    $self = bless {@args}, $self;

    my $level = uc $self->{level}; # // $LOG_INFO;
    if( $level =~ /^\d+$/ )
    {
        $level = $self->_level2asc( $level );
    }
    $self->{level_} = exists $METHODS{$level} ? $METHODS{$level} : $LOG_INFO;
    delete $self->{level};

    $self->{comments_} = parse_bool( $self->{comments} );
    delete $self->{comments};
    $self->{format_} = $self->{format} // $FMT_DEF;
    delete $self->{format};
    $self->{host_} = hostname;

    # group-specific parameters:
    if ( $self->{fields} ) {
        $self->{use_fields_} = 1;
        for ( ref $self->{fields} eq $ARRAY ? @{ $self->{fields} } : split /[,;\s]+/sm, $self->{fields} ) {
            $_ = lc;
            if ( $_ eq 'all' || $_ eq q{*} ) {
                %{ $self->{fields_} } = %FIELDS;
                last;
            }
            if ( exists $FIELDS{$_} ) {
                $self->{fields_}->{$_} = 1;
            }
            else {
                $self->{error} = sprintf 'Unknown field "%s" in fields parameter.', $_;
                return $self;
            }
        }
        delete $self->{fields};
        $self->{exe_} = $PROGRAM_NAME;
        @ARGV and $self->{exe_} .= q{ } . join q{ }, @ARGV;
    }

    my $package = ref $self;
    for my $method ( sort { length $a <=> length $b } keys %METHODS ) {
        my $level = $METHODS{$method};
        $self->{methods_}->{$level} = $method;
        $method = lc $method;
        no strict 'refs';
        *{"$package\::$method"} = sub {
            my $this = shift;
            local *__ANON__ = __PACKAGE__ . "::$method";
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

    if( $self->{async} || $self->{nb} ) {
        $self->nb();
        delete $self->{async};
        delete $self->{nb};
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub comments
{
    ( $self->{comments_} ) = @args;
    return $self;
}

# ------------------------------------------------------------------------------
sub nb
{   
    if ( !$self->{queue_} ) {
        push @NB_LOGGERS, $self;
        $self->{queue_}    = Thread::Queue->new;
        $self->{comments_} = shared_clone( $self->{comments_} );
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
    if ( $level <= $self->{level_} ) {
        my $msg = $self->_msg( $level, $sec, $microsec, $fmt, @data );
        $msg and $self->plog($msg);
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub END
{
    $_->DESTROY for @NB_LOGGERS;
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
        $self->{comments_} or return;
        $msg =~ s/^[';#\s]+//sm;
    }
    my $method = $self->{methods_}->{$level};

    if ( $self->{use_fields_} ) {
        $self->{log_} = { message => $msg };
        $self->{fields_}->{pid}   and $self->{log_}->{pid}   = $PID;
        $self->{fields_}->{level} and $self->{log_}->{level} = $method;
        $self->{fields_}->{exe}   and $self->{log_}->{exe}   = $self->{exe_};
        $self->{fields_}->{host}  and $self->{log_}->{host}  = $self->{host_};
        if ( $self->{fields_}->{tstamp} ) {
            $self->{log_}->{tstamp} = $sec * 1_000_000 + $microsec;
        }
        if ( $self->{fields_}->{trace} ) {
            my $depth = 3;
            my @stack;
            while ( my @caller = caller $depth ) {
                push @stack, sprintf '%u %s() at line %u of "%s"', $depth - 2, $caller[3], $caller[2], $caller[1];
                ++$depth;
            }
            $self->{log_}->{trace} = \@stack;
        }
    }
    return $self->_format( $sec, $microsec, $PID, $self->{host_}, $method, $msg );

    #    return sprintf '%s %-6u %s %s', ( strftime '%F %X', localtime $sec ), $PID, $method, $msg;
}

# ------------------------------------------------------------------------------
sub _format
{
    my ( $seconds, $microsec, $pid, $host, $method, $msg ) = @args;

=for comment
    %@  
        message
    %p 
        PID
    %l, %L 
        level
    %h
        host
        
    %d, %m, %y, %H, %M, %S 
        day, month, year, hour, min, sec (numeric)
    %F 
        alias for "%y-%m-%d", zero-padded
    %X 
        alias for "%H:%M:%S", zero-padded
    %Z 
        alias for "%F %X"
    %i
        microseconds

#########################
    %x
        executable
    %a
        arguments
    %t
        trace
#########################
=cut

    my $message = q{};

    #my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime $seconds;
    my @ltime = localtime $seconds;

    for my $fmt ( split /([%][-\d]{0,}[\w@])/sm, $self->{format_} ) {
        if ( $fmt =~ /^[%](.*)([\w@])$/gsm ) {
            my $sfmt = sprintf '%%%ss', $1;
            my $nfmt = sprintf '%%%su', $1;
            if ( $2 eq q{@} ) {
                $message .= sprintf $sfmt, $msg;
            }
            elsif ( $2 eq q{p} ) {
                $message .= sprintf $nfmt, $pid;
            }
            elsif ( $2 eq q{L} ) {
                $message .= sprintf $sfmt, uc $method;
            }
            elsif ( $2 eq q{l} ) {
                $message .= sprintf $sfmt, lc $method;
            }
            elsif ( $2 eq q{i} ) {
                $message .= sprintf $sfmt, $microsec;
            }
            elsif ( $2 eq q{X} ) {
                $message .= sprintf $sfmt, strftime '%X', @ltime;
            }
            elsif ( $2 eq q{d} ) {
                $message .= sprintf $nfmt, $ltime[3];
            }
            elsif ( $2 eq q{m} ) {
                $message .= sprintf $nfmt, $ltime[4] + 1;
            }
            elsif ( $2 eq q{y} ) {
                $message .= sprintf $nfmt, $ltime[5] + 1900;
            }
            elsif ( $2 eq q{H} ) {
                $message .= sprintf $nfmt, $ltime[2];
            }
            elsif ( $2 eq q{M} ) {
                $message .= sprintf $nfmt, $ltime[1];
            }
            elsif ( $2 eq q{S} ) {
                $message .= sprintf $nfmt, $ltime[0];
            }
            elsif ( $2 eq q{F} ) {
                $message .= sprintf $sfmt, strftime '%F', @ltime;
            }
            elsif ( $2 eq q{Z} ) {
                $message .= sprintf $sfmt, strftime '%F %X', @ltime;
            }
            elsif ( $2 eq q{h} ) {
                $message .= sprintf $sfmt, $host;
            }
            else {
                $message .= $_;
            }
        }
        else {
            $message .= $fmt;
        }
    }
    return $message;

    #    return sprintf '%s %-6u %s %s', ( strftime '%F %X', localtime $sec ), $pid, $method, $msg;
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
        level => $LOG_INFO, 
        comments => 1 
    );

=cut

# ------------------------------------------------------------------------------

