package Things::String;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Things::TieData;
use base qw/Things::TieData/;

use base qw/Exporter/;
our @EXPORT  = qw/string/;
our $VERSION = 'v1.1';

# ------------------------------------------------------------------------------
use overload

    # stringify:
    q{""} => sub {
    return shift->{data} // q{};
    },

    # copy constructor:
    q{=} => sub {
    shift;
    },
    q{+=} => sub {
        shift->{data} .= shift;
    },

    # concat:
    q{+} => \&_concat,
    q{&} => \&_concat,

    # inc/dec:
    q{++} => \&_inc,
    q{--} => \&_dec,

    # compare:
    q{<=>} => \&_cmp,
    q{cmp} => \&_cmp,
    q{==}  => \&_eq,
    q{!=}  => \&_ne,

    # repeat:
    q{x} => \&_rep,
    q{*} => \&_rep,
    ;

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub string
{
    if ( @_ > 2 or !exists $_[0] or defined $_[0] ) {
        Carp::confess 'Usage: string my $string [=> "string"] or [, "string"];';
    }
    bless \$_[0], __PACKAGE__;
    tie $_[0], __PACKAGE__, $_[1] || q{};
    return $_[0];
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
sub trim
{
    my ($self) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        Things::Trim::trim( $self->{data}, 1 );
        return $self->{data};
    }
    return trim $self;
}

# ------------------------------------------------------------------------------
sub chop
{
    my ($self) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        CORE::chop $self->{data};
        return $self->{data};
    }
    CORE::chop $self;
    return $self;
}

# ------------------------------------------------------------------------------
sub chomp
{
    my ($self) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        CORE::chomp $self->{data};
        return $self->{data};
    }
    CORE::chomp $self;
    return $self;
}

# ------------------------------------------------------------------------------
sub reverse
{
    my ($self) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::reverse $self->{data};
        return $self->{data};
    }
    return CORE::reverse $self;
}

# ------------------------------------------------------------------------------
sub substr
{
    my ($self, @args) = @_;
    if ( ref $self eq __PACKAGE__ ) {
        $self->{data} = CORE::substr $self->{data}, @args;
        return $self->{data};
    }
    return CORE::substr $self, @args;
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
sub _inc
{
    my ($self) = @_;

    # если строка пустая - делаем 'a':
    if ( !$self->{data} ) {
        $self->{data} = q{a};
        return $self;
    }

    my $c = CORE::substr $self->{data}, -1, 1;

    # проверяем что в конце цифра/буква, иначе инкремент не
    # пройдёт и вылезет warning:
    if ( $c =~ /^[[:alnum:]]$/ ) {

        # OK, обычный строковый инкремент
        ++$self->{data};
    }
    else {
        # укорачиваем строку:
        CORE::chop $self->{data};
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _dec
{
    my ($self) = @_;
    $self->{data} or return $self;

    my $c = CORE::substr $self->{data}, -1, 1;

    # в конце цифра? уменьшаем её,
    # или укорачиваем строку, если 0
    if ( $c =~ /^[[:digit:]]$/ ) {
        if ( $c eq q{0} ) {
            CORE::chop $self->{data};
        }
        else {
            --$c;
            $self->{data} =~ s/.$/$c/gsm;
        }
    }

    # буква - то же самое:
    elsif ( $c =~ /^[[:alpha:]]$/ ) {
        if ( $c eq q{A} ) {
            $c = q{z};
            $self->{data} =~ s/.$/$c/gsm;
        }
        elsif ( $c eq q{a} ) {
            CORE::chop $self->{data};
        }
        else {
            $c = chr ord($c) - 1;
            $self->{data} =~ s/.$/$c/gsm;
        }
    }
    else {
        CORE::chop $self->{data};
    }
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
 
    use Things::String;
    my $s = string 'abc';
    # OR
    # string my $s, 'def';
    # OR
    # string my $s => 'zxc';
    # ...

=cut

# ------------------------------------------------------------------------------
