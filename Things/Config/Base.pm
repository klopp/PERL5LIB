package Things::Config::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Encode qw/decode_utf8/;
use Try::Catch;

use Things::Bool qw/autodetect/;
use Things::Config::Find;
use Things::Const qw/:types/;
use Things::Xargs;
use Things::Xget;

our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub new
{
    $self = bless {}, $self;
    $self->{opt_} = selfopt( $self, @args );
    $self->{error} and return $self;

    if ( !$self->{opt_}->{file} ) {
        $self->{error} = 'No required {file} parameter';
        return $self;
    }

    if ( autodetect( $self->{opt_}->{file} ) ) {
        $self->{opt_}->{file} = Things::Config::Find->find;
        if ( !$self->{opt_}->{file} ) {
            $self->{error} = sprintf 'Can not find DEFAULT config file from: "%s"',
                join( q{", "}, Things::Config::Find->tested_files );
            return $self;
        }
    }

    try {
        $self->_parse();
        if ( ref $self->{_} ne $ARRAY && ref $self->{_} ne $HASH ) {
            Carp::croak sprintf 'Can not parse file "%s" (%s)', $self->{opt_}->{file}, $self->{error};
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
    return Carp::confess sprintf 'Method %s() must be overloaded', ( caller 0 )[3];
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
        }
        catch {
        };
    }
    return $src;
}

# ------------------------------------------------------------------------------
sub error
{
    return $self->{error};
}

# ------------------------------------------------------------------------------
sub get
{
    my ($xpath) = @args;
    $self->{opt_}->{nocase} and $xpath = lc $xpath;
    my $rc = xget( $self->{_}, $xpath );
    $rc or return q{};
    if ( ref $rc eq $HASH ) {
        return wantarray ? %{$rc} : ( $rc || q{} );
    }
    return wantarray ? @{$rc} : ( $rc->[-1] || q{} );
}

# ------------------------------------------------------------------------------
1;
__END__
