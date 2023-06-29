package Things::Log::Db;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
#   dbobj => OBJECT
#       DBI object with do()
#   table => STRING
#       table name
#   prefix => [STRING]
#       table column with log data, default 'log'
#   split => [FALSE]
#       if TRUE log data will be splitted:
#           log=message
#           tstamp=seconds OR milliseconds
#           level=LOG_LEVEL
#           pid=PID
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( !$self->{dbobj} ) {
        $self->{error} = 'No required "dbobj" parameter.';
        return $self;
    }
    if ( !$self->{table} ) {
        $self->{error} = 'No required "table" parameter.';
        return $self;
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _q
{
    return $self->{dbobj}->q(@args);
}

# ------------------------------------------------------------------------------
sub _print
{
    my ($msg) = @args;

    my ( @data, $q );
    if ( $self->{split} ) {
        push @data, $self->{log}->{tstamp};
        push @data, $self->{log}->{pid};
        push @data, $self->{log}->{level};
        push @data, $self->{log}->{ $self->{prefix} };
        $q = sprintf q{
            INSERT INTO %s (%s, %s, %s, %s) VALUES(?, ?, ?, ?)       
        }, $self->_q( $self->{table} ), $self->_q('tstamp'), $self->_q('pid'), $self->_q('level'),
            $self->_q( $self->{prefix} );
    }
    else {
        push @data, $msg;
        $q = sprintf q{
            INSERT INTO %s (%s) VALUES(?)       
        }, $self->_q( $self->{table} ), $self->_q( $self->{prefix} );
    }

    defined $self->{dbobj}->do( $q, undef, @data )
        or $self->{error} = $self->{dbobj}->errstr;

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
