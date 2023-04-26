package Things::Out;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use English qw/-no_match_vars/;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/puts fputs fprintf perror strerror strerr fopen/;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
use Try::Tiny;

# ------------------------------------------------------------------------------
BEGIN {
    *{strerr} = \&strerror;
}

# ------------------------------------------------------------------------------
sub puts
{
    unshift @_, *{STDOUT};
    goto &fputs;
}

# ------------------------------------------------------------------------------
sub fputs
{
    my ( $fh, $fmt, @args ) = @_;
    return printf {$fh} sprintf( "%s\n", $fmt ), @args;
}

# ------------------------------------------------------------------------------
sub fprintf
{
    my ( $fh, $fmt, @args ) = @_;
    return printf {$fh} $fmt, @args;
}

# ------------------------------------------------------------------------------
sub strerror
{
    my ($msg) = @_;
    defined $msg and return sprintf '%s: %s', $msg, $ERRNO;
    return $ERRNO;
}

# ------------------------------------------------------------------------------
sub perror
{
    return fputs( *{STDERR}, strerror(@_) );
}

# ------------------------------------------------------------------------------
sub fopen
{
    my ( $filename, $filemode ) = @_;
    my $fh = IO::File->new;
    try {
        if ( !open $fh, $filemode, $filename ) {
            Carp::croak strerror( sprintf 'Open file "%s"', $filename );
        }
    }
    catch {
        undef $fh;
        Carp::croak $_;
    };
    return $fh;
}

# ------------------------------------------------------------------------------

1;
