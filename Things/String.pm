package Things::String;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/&string/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use overload

    # copy constructor:
    q{=} => sub {
    return bless { data => shift->{data} }, __PACKAGE__;
    },

    # stringify:
    q{""} => sub {
    return shift->{data};
    },

    # concat:
    q{+=} => \&_concat,
    q{.=} => \&_concat,
    ;

# ------------------------------------------------------------------------------
sub string
{
    my ($data) = @_;
    return bless { data => $data }, __PACKAGE__;
}

# ------------------------------------------------------------------------------
sub _concat
{
    my ( $self, $tail ) = @_;
    $self->{data} //= q{};
    $tail //= q{};
    $self->{data} .= $tail;
    return $self->{data};
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
