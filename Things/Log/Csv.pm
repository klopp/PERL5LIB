package Things::Log::Csv;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Things::Log::CsvBase;
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
    return get_csv($self);
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    $msg = to_csv( $msg, $self );
    $msg and $self->SUPER::plog($msg);
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
