package Things::Args;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use utf8::all;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/xargs hargs/;
our $VERSION = 'v1.0';

use Things::Const qw/:types/;

# ------------------------------------------------------------------------------
sub xargs
{
    return shift if @_ == 1;
    goto &hargs
}

# ------------------------------------------------------------------------------
sub hargs
{
    my $args;
    if ( @_ == 1 ) {
        if ( ref $_[0] eq $HASH ) {
            $args = shift;
        }
        else {
            Carp::confess 'Not a HASH reference!';
        }
    }
    elsif ( @_ % 2 ) {
        Carp::confess 'Not a HASH!';
    }
    else {
        %{$args} = @_;
    }
    return $args;
}

# ------------------------------------------------------------------------------
1;
__END__
