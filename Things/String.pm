package Things::String;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/string/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use overload

    # stringify:
    q{""} => sub {
    return shift->{data};
    },

    # deref:
    q[${}] => sub {
    return \shift->{data};
    },

    # copy constructor:
    q{=} => sub {
    return bless { data => shift->{data} }, __PACKAGE__;
    },

    # concat:
    q{+} => \&_concat,
    q{&} => \&_concat,

    # compare:
    q{<=>} => \&_cmp,
    q{cmp} => \&_cmp,

    # repeat:
    q{x} => \&_rep,
    q{*} => \&_rep,
    ;

# ------------------------------------------------------------------------------
sub string
{
    my ($data) = @_;
    return bless { data => $data }, __PACKAGE__;
}

# ------------------------------------------------------------------------------
sub lc
{
    my ($self) = @_;

    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::lc $self->{data};
        return $self->{data};
    }
    return CORE::lc $self;
}

# ------------------------------------------------------------------------------
sub lcfirst
{
    my ($self) = @_;

    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::lcfirst $self->{data};
        return $self->{data};
    }
    return CORE::lcfirst $self;
}

# ------------------------------------------------------------------------------
sub uc
{
    my ($self) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::uc $self->{data};
        return $self->{data};
    }
    return CORE::uc $self;
}

# ------------------------------------------------------------------------------
sub ucfirst
{
    my ($self) = @_;

    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::ucfirst $self->{data};
        return $self->{data};
    }
    return CORE::ucfirst $self;
}

# ------------------------------------------------------------------------------
sub _concat
{
    my ( $s1, $s2, $invert ) = @_;
    return string $invert ? ( $s2 . $s1 ) : ( $s1 . $s2 );
}

# ------------------------------------------------------------------------------
sub _rep
{
    my ( $s1, $s2, $invert ) = @_;
    return string $invert ? ( "$s2" x int $s1 ) : ( "$s1" x int $s2 );
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
 
    use Things::String;
    my $string = string 'abc';
    # ...

=cut

# ------------------------------------------------------------------------------
