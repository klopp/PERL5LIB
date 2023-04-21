package Things::Bool;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/
        set_bool set_true set_false 
        true false True False TRUE FALSE 
        parse_bool
    /;
our $VERSION = 'v1.0';

use Things::Const qw/:types/;

# ------------------------------------------------------------------------------
sub TRUE  {1}
sub FALSE {0}
sub true  {1}
sub false {0}
sub True  {1}
sub False {0}

# ------------------------------------------------------------------------------
sub parse_bool
{
    $_[0] = ( $_[0] && $_[0] !~ /^0|no|false|none|never$/i ) ? 1 : 0;
    return $_[0];
}

# ------------------------------------------------------------------------------
sub set_true
{
    $_[1] = 1;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
sub set_false
{
    $_[1] = undef;
    goto &set_bool;
}

# ------------------------------------------------------------------------------
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
        Carp::cluck sprintf 'Target argument must be SCALAR REF at %s()', ( caller 0 )[3];
        return;
    }
    $_[0] = ( @_ == 1 || $_[1] ) ? 1 : undef;
    return $_[0];
}

# ------------------------------------------------------------------------------
1;
