package Things::Config::Perl;

use strict;
use warnings;

use Encode qw/decode_utf8/;
use English qw/-no_match_vars/;
use Try::Tiny;

use Things::Const qw/:types/;
use Things::Trim;
use Things::Xargs;
use Things::Xget;

our $VERSION = 'v1.1';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @args ) = @_;

    my $opt;
    my $self = bless {}, $class;

    try {
        $opt = xargs(@args);
    }
    catch {
        $self->{error} = $_;
    };
    $self->{error} and return $self;

    if ( !$opt->{file} ) {
        $self->{error} = 'No required "file" parameter';
        return $self;
    }

    my $cfg = do $opt->{file};
    if ( !$cfg ) {
        $self->{error} = $EVAL_ERROR ? trim($EVAL_ERROR) : trim($ERRNO);
        return $self;
    }

    $self->{_} = _multivals( $cfg, $opt );
    return $self;
}

#------------------------------------------------------------------------------
sub _multivals
{
    my ( $src, $opt ) = @_;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _lowercase_keys( $_, $opt ) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        for ( keys %{$src} ) {
            my $key   = $opt->{nocase} ? lc : $_;
            my $value = $src->{$_};
            if ( !ref $src->{$_} ) {
                try {
                    $value = decode_utf8 $value;
                };
            }
            push @{ $dest->{$key} }, $value;
        }
    }
    return $dest;
}

# ------------------------------------------------------------------------------
sub error
{
    my ($self) = @_;
    return $self->{error};
}

# ------------------------------------------------------------------------------
sub get
{
    my ( $self, $xpath ) = @_;
    my $rc = xget( $self->{_}, $xpath );
    $rc or return;
    return wantarray ? @{$rc} : $rc->[-1];
}

# ------------------------------------------------------------------------------
1;
