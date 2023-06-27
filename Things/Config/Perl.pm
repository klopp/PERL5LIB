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
our $VERSION = 'v1.1';

# ------------------------------------------------------------------------------
sub _parse
{
    my ( $file, $opt ) = @args;

    capture {
        my $cfg = do $file;
        if ( !$cfg ) {
            $self->{error} = $EVAL_ERROR ? $EVAL_ERROR : $ERRNO;
        }
        else {
            $self->{_} = _multivals( $cfg, $opt );
        }
    };
    return $self;
}

#------------------------------------------------------------------------------
sub _multivals
{
    my ( $src, $opt ) = @_;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _multivals( $_, $opt ) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        while ( my ($key) = each %{$src} ) {
            my $value = $src->{$key};
            $opt->{nocase} and $key = lc $key;
            push @{ $dest->{$key} }, _multivals($value);
        }
    }
    else {
        $dest = $src;
    }
    return $dest;
}

# ------------------------------------------------------------------------------
1;
