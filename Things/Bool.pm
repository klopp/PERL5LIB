package Things::Bool;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT = qw/
    set_bool set_true set_false
    true false True False TRUE FALSE
    parse_bool
    /;
our @EXPORT_OK = ( @EXPORT, 'autodetect' );

use Const::Fast;

use Things::Const qw/:types/;

const my %AUTODETECT => (
    q{?}      => 1,
    q{-}      => 1,
    q{*}      => 1,
    'auto'    => 1,
    'def'     => 1,
    'default' => 1,
    'detect ' => 1,
    'find'    => 1,
    'search'  => 1,
);

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub TRUE  {1}
sub FALSE {0}
sub true  {1}
sub false {0}
sub True  {1}
sub False {0}

# ------------------------------------------------------------------------------
sub autodetect
{
## no critic (RequireArgUnpacking)
    return exists $AUTODETECT{ $_[0] };
}

# ------------------------------------------------------------------------------
sub parse_bool
{
    my ($bool) = @_;
    return 0 if !$bool || $bool =~ /^0|off|no|false|none|never|jamais$/ism;
    return 1;
}

# ------------------------------------------------------------------------------
sub set_true
{
## no critic (RequireArgUnpacking)
    $_[1] = 1;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub set_false
{
    $_[1] = 0;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub set_bool
{

=for comment
    * выставить:
        $flag = set_bool($flag);
        $flag = set_bool($flag, 1);
    * сбросить:
        $flag = set_bool($flag, undef);
        $flag = set_bool($flag, 0);
    Использование в blessed:
        sub set_flag {
            my $self = shift;
            return set_bool($self->{flag}, @_ ? shift : 1);
        }
=cut

    if ( @_ < 1 ) {
        Carp::cluck sprintf 'No target argument at %s()', ( caller 0 )[3];
        return;
    }
    if ( ref \$_[0] ne $SCALAR ) {
        Carp::cluck sprintf 'Target argument must be %s REF at %s()', $SCALAR, ( caller 0 )[3];
        return;
    }
    $_[0] = ( @_ == 1 || $_[1] ) ? 1 : undef;
    return $_[0];
}

# ------------------------------------------------------------------------------
1;
