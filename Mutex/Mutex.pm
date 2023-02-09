package Mutex::Mutex;

# ------------------------------------------------------------------------------
use Mutex;

use Mutex::Base;
use base qw/Mutex::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @params ) = @_;
    my %self = ( mutex => Mutex->new(@params) );
    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
1;
__END__
