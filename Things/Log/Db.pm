package Things::Log::Db;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.00';

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
            INSERT INTO %s (tstamp, pid, level, %s) VALUES(?, ?, ?, ?)       
        }, $self->{table}, $self->{prefix};
    }
    else {
        push @data, $msg;
        $q = sprintf q{
            INSERT INTO %s (`%s`) VALUES(?)       
        }, $self->{table}, $self->{prefix};
    }

    defined $self->{dbobj}->do( $q, undef, @data )
        or $self->{error} = $self->{dbobj}->errstr;

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
