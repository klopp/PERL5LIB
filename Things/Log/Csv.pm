package Things::Log::Csv;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Text::CSV;

use Things::Log::File;
use base qw/Things::Log::File/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
#   file => FILE
#       log file
#   csv => [ method => value, ... ]
#       Text::CSV options
# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    $self->{error} and return $self;

    $self->{csv_}  = Text::CSV->new( $self->{csv} || {} );
    $self->{error} = Text::CSV->error_diag;
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    if ( $self->{split} ) {
        $self->{csv_}->combine(
            $self->{log_}->{exe}, $self->{log_}->{level}, $self->{log_}->{message},
            $self->{log_}->{pid}, $self->{log_}->{tstamp},
        );
    }
    else {
        $self->{csv_}->combine($msg);
    }
    $msg = $self->{csv_}->string;
    if ($msg) {
        $self->SUPER::plog($msg);
    }
    else {
        $self->{error} = $self->{csv_}->error_diag;
    }

    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Csv->new
    (
        file => '/var/log/my.log',
        csv  => [ key => value, ... ]
    );

=cut

# ------------------------------------------------------------------------------
