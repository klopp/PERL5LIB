package Things::Log::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Const::Fast;
use English qw/-no_match_vars/;
use POSIX qw/strftime/;

const my %LEVELS => (
    'EMERGENCY' => 0,
    'EMERG'     => 0,
    'ALERT'     => 1,
    'CRITICAL'  => 2,
    'CRIT'      => 2,
    'ERROR'     => 3,
    'ERR'       => 3,
    'WARNING'   => 4,
    'WARN'      => 4,
    'NOTICE'    => 5,
    'NOT'       => 5,
    'INFO'      => 6,
    'INF'       => 6,
    'DEBUG'     => 7,
    'DBG'       => 7,
    'TRACE'     => 8,
    'TRC'       => 8,
);

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
sub new
{
    $self = bless {@args}, $self;

    if ( !$self->{level} || !exists $LEVELS{ $self->{level} } ) {
        $self->{level} = 'INFO';
    }

    my $package = ref $self;
    while ( my ($key) = each %LEVELS ) {
        my $method = lc $key;
        no strict 'refs';
        *{"$package\::$method"} = sub {
            return shift->_log( $key, @_ );
        }
    }

    return $self;
}

# ------------------------------------------------------------------------------
sub _t
{
    return strftime '%F %X', localtime;
}

# ------------------------------------------------------------------------------
sub _msg
{
    my ( $level, $fmt, @data ) = @args;

    my $msg = sprintf $fmt, @data;
    if ( $msg =~ /^\s*[';#]/sm ) {
        $self->{comments} or return;
        $msg =~ s/^\s*[';#]+//sm;
    }
    return sprintf "%s %u %s %s\n", _t(), $PID, $level, $msg;
}

# ------------------------------------------------------------------------------
sub _log
{
    return $self if $self->{error};
    
    my ( $level, $fmt, @data ) = @args;

    if ( $LEVELS{$level} <= $LEVELS{ $self->{level} } ) {
        my $msg = $self->_msg( $level, $fmt, @data );
        $msg and $self->_print($msg);
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _print
{
    return Carp::croak sprintf 'Method %s() must be overloaded.', ( caller(0) )[3];
}

# ------------------------------------------------------------------------------
1;
__END__
