package Things::Log;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use English qw/-no_match_vars/;
use Const::Fast;
use Fcntl qw/:flock/;
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

# ------------------------------------------------------------------------------
sub new
{
    $self = bless {@args}, $self;

    $self->{file} or Carp::croak 'No required "file" parameter.';
    ( $self->{level} and exists $LEVELS{ $self->{level} } ) or $self->{level} = 'INFO';

    my $package = ref $self;
    while ( my ($key) = each %LEVELS ) {
        my $method = lc $key;
        no strict 'refs';
        *{"$package\::$method"} = sub {
            return shift->_log( $key, @_ );
        }
    }

    open( $self->{fh}, '>>', $self->{file} )
        or Carp::croak sprintf 'Can not open log file "%s" (%s)', $self->{file}, $ERRNO;
    $self->{fh}->autoflush(1);

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
    if ( $msg =~ /^\s*?[';#\/]/sm ) {
        $self->{comments} or return;
        $msg =~ s/^\s*?[';#\/]+\s*//;
    }
    return sprintf "%s %u %s %s\n", $self->_t(), $PID, $level, $msg;
}

# ------------------------------------------------------------------------------
sub _log
{
    my ( $level, $fmt, @data ) = @args;

    if ( $LEVELS{$level} <= $LEVELS{ $self->{level} } ) {
        my $msg = $self->_msg( $level, $fmt, @data );
        if ($msg) {
            flock( $self->{fh}, LOCK_EX );
            $self->{fh}->print($msg);
            flock( $self->{fh}, LOCK_UN );
        }
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    close $self->{fh};
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
