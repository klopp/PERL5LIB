package Things::Log::Json;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use JSON::XS;
use Try::Catch;

use Things::Log::File;
use base qw/Things::Log::File/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
#   json => [ method => value, ... ]
#       JSON::XS options
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    try {
        $self->{json} = JSON::XS->new;
        while ( my ( $method, $value ) = each %{ $self->{params}->{json} } ) {
            if ( $self->{json}->can($method) ) {
                $self->{json}->$method($value);
            }
        }
        $self->{json}->canonical(1);
    }
    catch {
        $self->{error} = sprintf 'JSON :: %s', $_;
    };
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;
    try {
        $msg = $self->{json}->encode( $self->{split} ? $self->{log_} : { $self->{root} => $msg } );
        $self->SUPER::plog($msg);
    }
    catch {
        $self->{error} = sprintf 'JSON :: %s', $_;
    };

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Json->new
    (
        file => '/var/log/my.log',
        json => [ key => value, ... ]
    );

=cut

# ------------------------------------------------------------------------------
