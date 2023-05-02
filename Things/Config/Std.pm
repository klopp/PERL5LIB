package Things::Config::Std;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Encode qw/decode_utf8/;
use Path::Tiny;
use String::Escape qw/unbackslash/;
use Try::Tiny;

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

    try {
        my @lines = path( $opt->{file} )->lines;
        $self->{_} = _parse( \@lines, $opt );
    }
    catch {
        $self->{error} = $_;
    };

    return $self;
}

# ------------------------------------------------------------------------------
sub _parse
{
    my ( $lines, $opt ) = @_;
    my %data;
    my $lineno  = 0;
    my $section = \%data;
    while ( my $line = shift @{$lines} ) {
        ++$lineno;
        trim( $line, 1 );
        next unless $line;
        next if $line =~ /^[;:#'\"]/sm;
        if ( $line =~ /^\[(\S+)\]$/sm ) {
            my @parts = split /\//, $1;
            $section = \%data;
            while ( my $part = shift @parts ) {
                $section = \%{ $section->{$part} };
            }
            next;
        }
        if ( $line =~ /^(\S+)\s+(.+)$/sm ) {
            my ( $key, $value ) = ( $1, $2 );
            $key = lc $key if $opt->{nocase};
            try {
                $value = decode_utf8 $value;
            };
            $value =~ s/^["]|["]$//gsm;
            push @{ $section->{$key} }, unbackslash($value);
        }
        else {
            Carp::confess sprintf 'Invalid config file "%s", line [%u]', $opt->{file}, $lineno;
        }
    }
    return \%data;
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
sub error
{
    my ($self) = @_;
    return $self->{error_};
}

# ------------------------------------------------------------------------------
1;
__END__
