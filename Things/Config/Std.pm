package Things::Config::Std;

use strict;
use warnings;
use Things::Const qw/:types/;
use Things::Trim;

use Encode qw/decode_utf8/;
use Config::Std;
use List::Util qw/any/;
use Try::Tiny;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $file, @multikeys ) = @_;

    my %self;
    if ( !$file ) {
        $self{error} = 'File parameter required.';
    }
    else {
        try {
            read_config $file => %self;
        }
        catch {
            $self{error} = trim($_);
        };

        if ( !$self{error} ) {

            for my $section ( keys %self ) {
                if ( !$section ) {
                    $self{_} = $self{$section};
                    delete $self{$section};
                    $section = q{_};
                }
                _lowercase_section( $self{$section} );
                my $all = any { $_ eq q{*} or /^all$/ism } @multikeys;
                $all = undef if any { $_ eq '-' } @multikeys;
                _multikeys( $self{$section}, $all, \@multikeys );
                _decode( $self{$section} );
            }
        }
    }
    return bless \%self, $class;
}

#------------------------------------------------------------------------------
sub _decode
{
    my ($hash) = @_;

    for my $key ( keys %{$hash} ) {
        if ( ref $hash->{$key} eq $ARRAY ) {
            for ( @{ $hash->{$key} } ) {
                try {
                    $_ = decode_utf8 $_;
                };
            }
        }
        else {
            try {
                $hash->{$key} = decode_utf8 $hash->{$key};
            };
        }
    }
    return $hash;
}

#------------------------------------------------------------------------------
sub _multikeys
{
    my ( $hash, $all, $multikeys ) = @_;

    for my $key ( keys %{$hash} ) {
        if ($all) {
            $hash->{$key} = [ $hash->{$key} ] unless ref $hash->{$key} eq $ARRAY;
            next;
        }
        if ( any { $_ eq $key } @{$multikeys} ) {
            $hash->{$key} = [ $hash->{$key} ] unless ref $hash->{$key} eq $ARRAY;
        }
        else {
            $hash->{$key} = pop @{ $hash->{$key} } if ref $hash->{$key} eq $ARRAY;
        }
    }
    return $hash;
}

#------------------------------------------------------------------------------
sub _lowercase_section
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

# ------------------------------------------------------------------------------
sub error
{
    my ($self) = @_;
    return $self->{error};
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
