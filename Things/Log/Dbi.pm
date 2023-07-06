package Things::Log::Dbi;

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
#   root => [STRING]
#       table column with log data, default 'message'
#   split => [FALSE]
#       if TRUE log data will be splitted:
#           message=message
#           tstamp=seconds OR microseconds
#           level=LOG_LEVEL
#           pid=PID
#           exe=$PROGRAM_NAME @ARGV
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
sub plog
{
    my ($msg) = @args;

    my ( @data, $q );
    if ( $self->{split} ) {
        @data = (
            $self->{log_}->{tstamp},
            $self->{log_}->{pid},
            $self->{log_}->{exe},
            $self->{log_}->{level},
            $self->{log_}->{ $self->{root} }
        );
        $q = sprintf q{
            INSERT INTO `%s` (`tstamp`, `pid`, `exe`, `level`, `%s`) VALUES(?, ?, ?, ?, ?)       
        }, $self->{table}, $self->{root};
    }
    else {
        @data = ($msg);
        $q = sprintf q{
            INSERT INTO `%s` (`%s`) VALUES(?)       
        }, $self->{table}, $self->{root};
    }

    defined $self->{dbobj}->do( $self->{dbobj}->qi($q), undef, @data )
        or $self->{error} = $self->{dbobj}->errstr;

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
