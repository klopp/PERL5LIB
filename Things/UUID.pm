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
    q{==}  => \&_eq,
    q{!=}  => \&_ne,
    ;

# ------------------------------------------------------------------------------
## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
sub uuid(;$)
{
    use DDP;
    p @_;
    if ( !exists $_[0] ) {
        return bless { uuid => UUID::uuid }, __PACKAGE__;
    }
    if ( Scalar::Util::readonly $_[0] ) {
        Carp::confess sprintf 'Call %s() without arguments!', ( caller(0) )[3];
    }
    $_[0] = bless { uuid => UUID::uuid }, __PACKAGE__;
    return $_[0];
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
sub _eq
{
    my ( $s1, $s2 ) = @_;
    return "$s1" eq "$s2";
}

# ------------------------------------------------------------------------------
sub _ne
{
    my ( $s1, $s2 ) = @_;
    return "$s1" ne "$s2";
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Things::UUID;
    uuid my $uuid;
    # OR
    # my $uuid = uuid;
    puts( $uuid );   # stringify $uuid
    $uuid++;         # generate next UUID
    puts( $uuid );
    puts( ++$uuid ); # and next
    # ...

=cut

# ------------------------------------------------------------------------------
