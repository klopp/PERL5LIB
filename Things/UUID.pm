package Things::UUID;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/uuid/;
our $VERSION = 'v1.0';

use UUID;

# ------------------------------------------------------------------------------
use overload

    # stringify:
    q{""} => sub {
    return shift->{uuid};
    },

    # copy constructor:
    q{=} => sub {
    bless { data => shift->{uuid} }, __PACKAGE__;
    },

    # inc:
    q{++} => \&_inc,

    # compare:
    q{<=>} => \&_cmp,
    q{cmp} => \&_cmp,
    ;

# ------------------------------------------------------------------------------
sub uuid(\$)
{
    #    my ($data) = @_;
    ${ $_[0] } = bless { uuid => UUID::uuid }, __PACKAGE__;
    return;
}

# ------------------------------------------------------------------------------
sub _inc
{
    my ($self) = @_;
    $self->{uuid} = UUID::uuid;
    return $self;
}

# ------------------------------------------------------------------------------
sub _cmp
{
    my ( $s1, $s2, $invert ) = @_;
    return $invert ? ( "$s2" cmp "$s1" ) : ( "$s1" cmp "$s2" );
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Things::UUID;
    uuid my $uuid;
    puts( $uuid );
    $uuid++; # generate next UUID
    puts( $uuid );
    # ...

=cut

# ------------------------------------------------------------------------------
