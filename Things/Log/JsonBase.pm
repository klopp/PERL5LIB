package Things::Log::JsonBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use JSON::XS;
use Try::Catch;

use Exporter qw/import/;
our @EXPORT = qw/get_json to_json/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
sub get_json
{
    my ($logger) = @_;
    try {
        $logger->{json_} = JSON::XS->new;
        while ( my ( $method, $value ) = each %{ $logger->{json} } ) {
            if ( $logger->{json_}->can($method) ) {
                $logger->{json_}->$method($value);
            }
        }
        $logger->{json_}->canonical(1);
    }
    catch {
        $logger->{error} = sprintf 'JSON :: %s', $_;
    };
    return $logger;
}

# ------------------------------------------------------------------------------
sub to_json
{
    my ( $msg, $logger ) = @_;
    try {
        $msg = $logger->{json_}->encode( $logger->{split} ? $logger->{log_} : { $logger->{caption} => $msg } );
    }
    catch {
        undef $msg;
        $logger->{error} = sprintf 'JSON :: %s', $_;
    };

    return $msg;
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
