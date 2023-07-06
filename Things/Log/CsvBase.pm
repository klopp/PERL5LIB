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
    $logger->{csv}->{binary} = 1;
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
        my $log_data = $logger->{log_};
        $log_data->{trace} and $log_data->{trace} = join "\n", @{$log_data->{trace}};
        my @values;
        push @values, $log_data->{$_} for sort keys %{$log_data};
        $logger->{csv_}->combine( @values );
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
