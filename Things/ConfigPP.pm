package Things::ConfigPP;

use lib q{.};
use StdUse;
use Things qw/:types trim/;

use Encode qw/decode_utf8/;
use English qw/-no_match_vars/;
use Config::Std;
use List::Util qw/any none/;
use Try::Tiny;

our $VERSION = 'v1.0';

use DDP;

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $file, @multikeys ) = @_;

    my $self;
    if ( !$file ) {
        $self->{error_} = 'File parameter required.';
    }
    else {

        my $cfg = do $file;

        if ( !$cfg ) {
            $self->{error_} = $EVAL_ERROR ? $EVAL_ERROR : $ERRNO;
            trim $self->{error_};
        }
        else {
            $self = _lowercase_keys($cfg);
            _multikeys( $self, ( any { $_ eq q{*} or /^all$/ism } @multikeys ), \@multikeys );
            $self = _decode($self);
        }
    }
    return bless $self, $class;
}

#------------------------------------------------------------------------------
sub _decode
{
    my ($src) = @_;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _decode($_) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        %{$dest} = map { $_ => _decode( $src->{$_} ) } keys %{$src};
    }
    else {
        try {
            $dest = decode_utf8 $src;
        };
    }
    return $dest;
}

#------------------------------------------------------------------------------
sub _multikeys
{
    my ( $src, $all, $multikeys ) = @_;

    if ( ref $src eq $ARRAY ) {
        _multikeys( $_, $all, $multikeys ) for @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        for my $key ( keys %{$src} ) {
            if ($all) {
                $src->{$key} = [ $src->{$key} ] unless ref $src->{$key} eq $ARRAY;
                next;
            }
            if ( any { $_ eq $key } @{$multikeys} ) {
                $src->{$key} = [ $src->{$key} ] unless ref $src->{$key} eq $ARRAY;
            }
            else {
                $src->{$key} = pop @{ $src->{$key} } if ref $src->{$key} eq $ARRAY;
            }
        }
    }

    return $src;
}

#------------------------------------------------------------------------------
sub _lowercase_hash
{
    my ($hash) = @_;
    for ( keys %{$hash} ) {
        if ( !/^[[:lower:]]+$/sm ) {
            my $lkey = lc;
            if ( exists $hash->{$lkey} ) {
                if ( ref $hash->{$lkey} ne $ARRAY ) {
                    $hash->{$lkey} = [ $hash->{$lkey} ];
                }
                if ( ref $hash->{$_} eq $ARRAY ) {
                    for my $value ( @{ $hash->{$_} } ) {
                        push @{ $hash->{$lkey} }, $value;
                    }
                }
                else {
                    push @{ $hash->{$lkey} }, $hash->{$_};
                }
            }
            else {
                $hash->{$lkey} = $hash->{$_};
            }
            delete $hash->{$_};
        }
    }
    return $hash;
}

#------------------------------------------------------------------------------
sub _lowercase_keys
{
    my ($src) = @_;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _lowercase_keys($_) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        $dest = _lowercase_hash($src);
    }
    return $dest;
}

# ------------------------------------------------------------------------------
sub error
{
    my ($self) = @_;
    return ref $self eq $HASH ? $self->{error_} : undef;
}

# ------------------------------------------------------------------------------
sub get
{
    my ( $self, $section, $key ) = @_;
    return $self->{$section}->{$key} if $key;
    return $self->{$section}         if $section;
    return $self;
}

# ------------------------------------------------------------------------------
1;
