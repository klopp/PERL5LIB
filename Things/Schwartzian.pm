package Things::Schwartzian;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT_OK = qw/Sch/;
our $VERSION   = 'v1.0';

# ------------------------------------------------------------------------------
sub Sch
{
    my ( $list, $get_prop, $compare ) = @_;

    my @sorted = map { $_->[0] }
        sort { $compare->( $a->[1], $b->[1] ) }
        map { [ $_, $get_prop->($_) ] } @{$list};
    return wantarray ? @sorted : \@sorted;
}

# ------------------------------------------------------------------------------
1;
