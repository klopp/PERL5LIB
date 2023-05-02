package Things::Config::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Encode qw/decode_utf8/;
use Path::ExpandTilde;
use Try::Tiny;

use Things::Config::Find;
use Things::Const qw/:types/;
use Things::Xargs;
use Things::Xget;

CORE::state %DEF_CONFIG = (
    q{?}      => 1,
    q{-}      => 1,
    q{*}      => 1,
    'def'     => 1,
    'default' => 1,
    'find'    => 1,
    'search'  => 1,
);
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @args ) = @_;

    my $self = bless {}, $class;

    my $opt;
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

    if ( $DEF_CONFIG{ $opt->{file} } ) {
        $opt->{file} = Things::Config::Find->find;
        if ( !$opt->{file} ) {
            $self->{error} = sprintf 'Can not find DEFAULT config file from: %s',
                join( q{, }, Things::Config::Find->tested_files );
            return $self;
        }
    }

    try {
        $self->_parse( expand_tilde( $opt->{file} ), $opt );
        if ( ref $self->{_} ne $ARRAY && ref $self->{_} ne $HASH ) {
            Carp::croak sprintf 'Can not parse file "%s"', $opt->{file};
        }
    }
    catch {
        $self->{error} = $_;
    };
    $self->{error} and return $self;

    _decode( $self->{_} );

    return $self;
}

# ------------------------------------------------------------------------------
sub _parse
{
    Carp::confess sprintf 'Method %s() must be overloaded', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub _decode
{
    my ($src) = @_;
    if ( ref $src eq $ARRAY ) {
        @{$src} = map { _decode($_) } @{$src};
    }
    elsif ( ref $src eq $HASH ) {
        while ( my ($key) = each %{$src} ) {
            $src->{$key} = _decode( $src->{$key} );
        }
    }
    else {
        try {
            $src = decode_utf8 $src;
        };
    }
    return $src;
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
__END__
