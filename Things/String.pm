package Things::String;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/string/;
our $VERSION = 'v1.0';

use DDP;
use Tie::Simple;
#use parent qw/Tie::StdScalar/;

# ------------------------------------------------------------------------------
use overload

    # nomethod
    q{nomethod} => \&_nomethod,

    # stringify:
    q{""} => sub {
#    printf 'stringify() :: %s', np @_;
    return shift->{data};
    },

    # deref:
    q[${}] => sub {
    my $data = ${shift->{data}};
    $data;
    },

    # copy constructor:
    q{=} => sub {
    printf '=() ';
    bless { data => shift->{data} }, __PACKAGE__;
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
    q{!=}  => \&_ne,
    q{==}  => \&_eq,

    # repeat:
    q{x} => \&_rep,
    q{*} => \&_rep,
    ;

# ------------------------------------------------------------------------------
sub _FETCH
{
    my ( $self ) = @_;
    printf "fetch()\n";
    p $self;
    return $self;
}

sub _STORE
{
    my ( $self, $data ) = @_;
    printf "store()\n";
    $self->{data} = $data;
    return $self;
}

sub _TIESCALAR
{
    my ( $class, $data ) = @_;
    my $self = bless { data => $data }, $class;
    return $self;    
}

# ------------------------------------------------------------------------------
sub _nomethod
{
    printf 'nomethod() :: %s', np @_;
#    my ( $self, $data ) = @_;
#    $self->{data} = $data;
#    return $self;
}

# ------------------------------------------------------------------------------
## no critic (ProhibitSubroutinePrototypes, RequireArgUnpacking)
sub string(\$;$)
{
#    printf 'string(->) :: %s', np @_;
    my $data = $_[1] || '';
#    my $self =  { data => $data };
#    ${ $_[0] } = bless { data => $data }, __PACKAGE__;
    tie my $var, 'Tie::Simple', $data,
        FETCH => \&_FETCH,
        STORE => \&_STORE,
        TIESCALAR => \&_TIESCALAR,
        ;
#    printf 'string(<-) :: %s', np @_;
    ${ $_[0] } = $var;
    return;
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
    string my $s => $invert ? ( $s2 . $s1 ) : ( $s1 . $s2 );
    return $s;
}

# ------------------------------------------------------------------------------
sub _rep
{
    my ( $s1, $s2, $invert ) = @_;
    string my $s => $invert ? ( "$s2" x int $s1 ) : ( "$s1" x int $s2 );
    return $s;
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

    my $c = substr $self->{data}, -1, 1;
    # проверяем что в конце цифра/буква, иначе инкремент не
    # пройдёт и вылезет warning:
    if ( $c =~ /^[[:alnum:]]$/ ) {
        # OK, обычный строковый инкремент
        ++$self->{data};
    }
    else {
        # укорачиваем строкку:
        chop $self->{data};
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _dec
{
    my ($self) = @_;
    $self->{data} or return $self;

    my $c = substr $self->{data}, -1, 1;
    # в конце цифра? уменьшаем её,
    # или укорачиваем строку, если 0
    if ( $c =~ /^[[:digit:]]$/ ) {
        if ( $c eq q{0} ) {
            chop $self->{data};
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
            chop $self->{data};
        }
        else {
            $c = chr ord($c) - 1;
            $self->{data} =~ s/.$/$c/gsm;
        }
    }
    else {
        chop $self->{data};
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
    return "$s2" eq "$s1";
}

# ------------------------------------------------------------------------------
sub _ne
{
    my ( $s1, $s2 ) = @_;
    return "$s2" ne "$s1";
}

# ------------------------------------------------------------------------------
1;
__END__

=pod
 
=head1 SYNOPSIS
 
    use Things::String;
    my $string = string 'abc';
    $string->ucfirst;
    # ...

=cut

# ------------------------------------------------------------------------------
