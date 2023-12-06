package Things::Config::Perl;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Capture::Tiny qw/capture/;
use English qw/-no_match_vars/;

use Things::Const qw/:types/;

use Things::Config::Base;
use base qw/Things::Config::Base/;
our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub _parse
{
    capture {
        my $cfg = do $self->{opt_}->{file};
        if ( !$cfg ) {
            $self->{error} = $EVAL_ERROR ? $EVAL_ERROR : $ERRNO;
        }
        else {
            $self->{_} = $self->_multivals( $cfg );
        }
    };
    return $self;
}

#------------------------------------------------------------------------------
sub _multivals
{
    my ( $src ) = @args;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { $self->_multivals( $_ ) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        while ( my ($key) = each %{$src} ) {
            my $value = $src->{$key};
            $self->{opt_}->{nocase} and $key = lc $key;
            push @{ $dest->{$key} }, $self->_multivals( $value );
        }
    }
    else {
        $dest = $src;
    }
    return $dest;
}

# ------------------------------------------------------------------------------
1;
