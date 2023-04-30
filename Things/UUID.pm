package Things::UUID;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;
use English;

# ------------------------------------------------------------------------------
use base qw/Exporter/;

our @EXPORT  = qw/$uuid/;
our $VERSION = 'v1.3';

use Things::TieData;
use base qw/Things::TieData/;
use UUID;
our $uuid;

# ------------------------------------------------------------------------------
BEGIN {
    bless \$uuid, __PACKAGE__;
    tie $uuid, __PACKAGE__, UUID::uuid;
}

# ------------------------------------------------------------------------------
sub import
{
    my ( $class, $export ) = @_;
    if ( @_ > 2 ) {
        Carp::confess 'Only one name can be exported.';
    }
    if ($export) {
        if ( $export !~ /^\$[[:alpha:]][[:alnum:]]*$/sm ) {
            Carp::confess sprintf 'Name "%s" is incorrect.', $export;
        }
        no strict 'refs';
        *{ __PACKAGE__ . '::' . ( substr $export, 1 ) } = \$uuid;
    }
    else {
        $export = '$uuid';
    }

    @EXPORT = ($export);
    @_      = ( $class, $export );
    goto &Exporter::import;
}

# ------------------------------------------------------------------------------
use overload

    # stringify:
    q{""} => sub {
    return shift->{data};
    },

    # copy constructor:
    q{=} => sub {
    shift;
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
sub _inc
{
    my ($self) = @_;
    $self->{data} = UUID::uuid;
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
 
    use Things::UUID; # $uuid exported
    puts( $uuid );    # stringify $uuid
    $uuid++;          # generate next UUID
    puts( $uuid );
    puts( ++$uuid );  # and next
    # ...

=cut

# ------------------------------------------------------------------------------
