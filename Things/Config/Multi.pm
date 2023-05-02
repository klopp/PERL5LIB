package Things::Config::Multi;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Things::Args;
use Things::Const qw/:types/;
use Things::Trim;
use Things::Xget;

use Encode qw/decode_utf8/;
use Path::Tiny;
use String::Escape qw/unbackslash/;
use Try::Tiny;
our $VERSION = 'v1.1';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @args ) = @_;

    my $opt = hargs(@args);
    $opt->{file} or Carp::confess 'No required "file" parameter';

    my @lines = path( $opt->{file} )->lines;

    $opt->{_} = _parse( \@lines, $opt );
    my $self = bless $opt, $class;
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
        next if $line =~ /^[;#'\"$%\@]/sm;
        if ( $line =~ /^\[(.+)\]$/sm ) {
            my @parts = split /[.]/, $1;
            $section = \%data;
            while ( my $part = shift @parts ) {
                $section = \%{ $section->{$part} };
            }
            next;
        }
        if ( $line =~ /^(\S+)[\s=]*(.*)$/ism ) {
            my ( $key, $value ) = ( $1, $2 );
            $key = lc $key if $opt->{nocase};
            try {
                $value = decode_utf8 $value;
            };
            $value =~ s/^["]|["]$//gsm;
            push @{ $section->{$key} }, unbackslash($value);
        }
        else {
            Carp::confess 'Invalid config file line [%u]', $lineno;
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
1;
__END__
