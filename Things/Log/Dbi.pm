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
#       DBI object
#   table => STRING
#       table name
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
sub qi
{
    my ($ident) = @args;
    return $self->{dbobj_}->quote_identifier($ident);
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    my ( @data, $q );

    if ( $self->{use_fields_} ) {
        my $log_data = $self->{log_};
        my @fields;
        my @placeholders;
        $log_data->{trace} and $log_data->{trace} = join "\n", @{ $log_data->{trace} };
        for ( keys %{$log_data} ) {
            push @fields,       $self->qi($_);
            push @data,         $log_data->{$_};
            push @placeholders, q{?};
        }

        $q = sprintf q{
            INSERT INTO %s (%s) VALUES(%s)       
        }, $self->qi( $self->{dbtable_} ), join( q{,}, @fields ), join( q{,}, @placeholders );
    }
    else {
        @data = ($msg);
        $q    = sprintf q{
            INSERT INTO %s (%s) VALUES(?)       
        }, $self->qi( $self->{dbtable_} ), $self->qi('message');
    }

    defined $self->{dbobj_}->do( $q, undef, @data )
        or $self->{error} = $self->{dbobj_}->errstr;

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
