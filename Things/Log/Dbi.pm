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
    $self->{dbobj_}   = $self->{dbobj};
    $self->{dbtable_} = $self->{table};
    delete $self->{table};
    delete $self->{dbobj};
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    my ( @data, $q );

    if ( $self->{fields_} ) {
        my $log_data = $self->{log_};
        my @fields;
        my @placeholders;
        $log_data->{trace} and $log_data->{trace} = join "\n", @{ $log_data->{trace} };
        for ( keys %{$log_data} ) {
            push @fields,       "`$_`";
            push @data,         $log_data->{$_};
            push @placeholders, q{?};
        }

        $q = sprintf q{
            INSERT INTO `%s` (%s) VALUES(%s)       
        }, $self->{dbtable_}, join( q{,}, @fields ), join( q{,}, @placeholders );
    }
    else {
        @data = ($msg);
        $q    = sprintf q{
            INSERT INTO `%s` (`message`) VALUES(?)       
        }, $self->{dbtable_};
    }

    defined $self->{dbobj_}->do( $self->{dbobj_}->qi($q), undef, @data )
        or $self->{error} = $self->{dbobj_}->errstr;

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
