package Things::Log::Std;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use English qw/-no_match_vars/;
use Tie::STDERR \&_std_notice;

use Things::Trim;

use Things::Log::File;
use base qw/Things::Log::File/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.00';
CORE::state $std;

# ------------------------------------------------------------------------------
sub new
{
    if ( !$std ) {
        my %hargs = @args;
        $hargs{file} = q{-};
        $std = $self->SUPER::new(%hargs);
    }
    return $std;
}

# ------------------------------------------------------------------------------
sub _std_notice
{
    $std and $std->notice( trim($self) );
}

# ------------------------------------------------------------------------------
$SIG{__WARN__} = sub { my ($msg) = @_; $std and $std->warn( trim($msg) ); };
$SIG{__DIE__}  = sub {
    my ($msg) = @_;
    $std and $std->emergency( trim($msg) );
    local *STDERR;
    untie *STDERR;
    die $msg;
};

# ------------------------------------------------------------------------------

1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Std->new( comments => 1 );  
    # STDERR redirect:
    # die    => $logger->emergency() + die
    # warn   => $logger->warn()
    # STDERR => $logger->notice()
=cut

# ------------------------------------------------------------------------------
