package Things::Log::CsvBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Text::CSV;

use Exporter qw/import/;
our @EXPORT = qw/get_csv to_csv/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
sub get_csv
{
    my ($logger) = @_;
    $logger->{csv_} = Text::CSV->new( $logger->{csv} || {} );
    delete $logger->{csv};
    $logger->{error} = Text::CSV->error_diag;
    return $logger;
}

# ------------------------------------------------------------------------------
sub to_csv
{
    my ( $msg, $logger ) = @_;
    if ( $logger->{split_} ) {
        $logger->{csv_}->combine(
            $logger->{log_}->{exe}, $logger->{log_}->{level}, $logger->{log_}->{message},
            $logger->{log_}->{pid}, $logger->{log_}->{tstamp},
        );
    }
    else {
        $logger->{csv_}->combine($msg);
    }
    $msg = $logger->{csv_}->string;
    $msg or $logger->{error} = $logger->{csv_}->error_diag;
    return $msg;
}

# ------------------------------------------------------------------------------
1;
__END__
