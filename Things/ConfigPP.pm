package Things::ConfigPP;

use lib q{.};
use StdUse;
use Things qw/:types trim xget/;

use Const::Fast;
use Encode qw/decode_utf8/;
use English qw/-no_match_vars/;
use List::Util qw/any/;
use Try::Tiny;

our $VERSION = 'v1.1';
const my $PKG_KEY => q{_} . __PACKAGE__ . q{_};

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
            my $all = any { $_ eq q{*} or /^all$/ism } @multikeys;
            $all = undef if any { $_ eq '-' } @multikeys;
            _multikeys( $self, $all, \@multikeys );
            $self = _decode($self);
####            $self->{ data } = $self;
        }
    }
    return bless { _ => $self }, $class;
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
        my $pkey = $PKG_KEY . lc;
        push @{ $hash->{$pkey} }, $hash->{$_};
    }
    return $hash;
}

#------------------------------------------------------------------------------
sub _keys_back
{
    my ($src) = @_;

    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _keys_back($_) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        my $pkey = $PKG_KEY . '([[:lower:]]+)';
        for ( keys %{$src} ) {
            $dest->{$1} = $src->{$_} if /$pkey/;
        }
    }
    return $dest;
}

#------------------------------------------------------------------------------
sub _lowercase_keys
{
    my ( $src, $level ) = @_;

    $level ||= 0;
    my $dest;
    if ( ref $src eq $ARRAY ) {
        @{$dest} = map { _lowercase_keys( $_, $level + 1 ) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        for ( keys %{$src} ) {
            push @{ $dest->{ $PKG_KEY . lc } }, $src->{$_};
        }
    }
    return $level ? $dest : _keys_back($dest);
}

# ------------------------------------------------------------------------------
sub error
{
    my ($self) = @_;
    return $self->{error_};
}

# ------------------------------------------------------------------------------
sub get
{
    my ( $self, $path ) = @_;
    return xget( $self->{_}, lc $path );
}

# ------------------------------------------------------------------------------
1;
