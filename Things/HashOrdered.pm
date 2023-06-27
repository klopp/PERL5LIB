package Things::HashOrdered;

use strict;
use warnings;
use self;
our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
use Hash::Ordered;
use base qw/Hash::Ordered/;

# ------------------------------------------------------------------------------
=for comment
    Надстройка над Hash::Ordered, позволяет использовать
    обычный синтаксис each и $hash->{}
=cut

use overload
    '%{}' => sub {
    return shift->[0];
    };

sub new
{
    return $self->SUPER::new(@args);
}

# ------------------------------------------------------------------------------
1;
__END__
