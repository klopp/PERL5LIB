package Things::Config::Std;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Path::Tiny;
use String::Escape qw/unbackslash/;

use Things::Trim;

use Things::Config::Base;
use base qw/Things::Config::Base/;
our $VERSION = 'v2.0';

# ------------------------------------------------------------------------------
sub _parse
{
    my @lines   = path( $self->{opt_}->{file} )->lines;
    my $lineno  = 0;
    my $section = \%{ $self->{_} };
    while ( my $line = shift @lines ) {
        ++$lineno;
        trim( $line, 1 );
        next unless $line;
        next if $line =~ /^[;:#'\"]/sm;
        if ( $line =~ /^\[(\S+)\]$/sm ) {
            my @parts = split /\//, $1;
            $section = \%{ $self->{_} };
            while ( my $part = shift @parts ) {
                $self->{opt_}->{nocase} and $part = lc $part;
                $section = \%{ $section->{$part} };
            }
            next;
        }
        if ( $line =~ /^(\S+)\s+(.+)$/sm ) {
            my ( $key, $value ) = ( $1, $2 );
            $key = lc $key if $self->{opt_}->{nocase};
            $value =~ s/^["]|["]$//gsm;
            push @{ $section->{$key} }, unbackslash($value);
        }
        else {
            Carp::croak sprintf 'Invalid config file "%s", line [%u]', $self->{opt_}->{file}, $lineno;
        }
    }
    return $self->{_};
}

# ------------------------------------------------------------------------------
1;
__END__
