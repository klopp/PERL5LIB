package Things::HashOrdered;

# ------------------------------------------------------------------------------
use Hash::Ordered;
use base qw/Hash::Ordered/;

=for comment
    Надстройка над Hash::Ordered, позволяет использовать
    обычный синтаксис each и $hash->{}.
    Экспортируется всегда.
=cut

use overload
    '%{}' => sub {
    return shift->[0];
    };

sub new
{
    return shift->SUPER::new(@_);
}

# ------------------------------------------------------------------------------
1;
__END__
