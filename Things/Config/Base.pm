package Things::Config::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Encode qw/decode_utf8/;
use Try::Tiny;

use Things::Const qw/:types/;
use Things::Xargs;
use Things::Xget;

our $VERSION = 'v1.0';

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

    try {
        $self->_parse($opt);
    }
    catch {
        $self->{error} = $_;
    };

    _decode( $self->{_} );
    return $self;
}

# ------------------------------------------------------------------------------
sub _parse
{
    Carp::confess sprintf 'Method %s() must be overloaded';
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
