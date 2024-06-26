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
our $VERSION = 'v2.2';

# ------------------------------------------------------------------------------
sub _parse
{
    my @lines   = path( $self->{opt_}->{file} )->lines;
    my $lineno  = 0;
    my $cmt     = 0;
    my $section = \%{ $self->{_} };

    while ( my $line = shift @lines ) {
        ++$lineno;
        trim( $line, 1 );
        next unless $line;
        next if $line =~ /^[;:#'\"]/sm;

        if ( $line eq q{/*} ) {
            ++$cmt;
        }
        elsif ( $line eq q{*/} ) {
            --$cmt;
            $cmt < 0 and Carp::croak sprintf 'Invalid config file "%s", line [%u]', $self->{opt_}->{file}, $lineno;
            next;
        }
        $cmt and next;

        while ( $line =~ / \\\\$/sm ) {
            my $next = shift @lines;
            ++$lineno;
            trim( $next, 1 );
            $line =~ s/[ \t]+\\\\$//sm;
            $line .= "\n" . $next;
        }

        while ( $line =~ / \\$/sm ) {
            my $next = shift @lines;
            ++$lineno;
            trim( $next, 1 );
            $line =~ s/[ \t]+\\$//sm;
            $line .= q{ } . $next;
        }

        if ( lc $line eq '[end]' ) {
            $section = \%{ $self->{_} };
        }
        elsif ( $line =~ /^\[(\S+)\]$/sm ) {
            my @parts = split /\//, $1;
            $section = \%{ $self->{_} };
            while ( my $part = shift @parts ) {
                $self->{opt_}->{nocase} and $part = lc $part;
                $section = \%{ $section->{$part} };
            }
        }
        elsif ( $line =~ /^(\S+)\s+(.+)$/sm ) {
            my ( $key, $value ) = ( $1, $2 );
            $key = lc $key if $self->{opt_}->{nocase};
            $value =~ s/^["]|["]$//gsm;
            $value =~ s/\$ENV\{([^}]+)\}/$ENV{$1}/gsm;
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
