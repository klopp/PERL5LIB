package Things::LdLibraryPath;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Const::Fast;
use List::MoreUtils qw/any/;
use Path::Tiny;

use DDP;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT = qw/exec_with_llp/;

# ------------------------------------------------------------------------------
const my $LD_SO_CONF => '/etc/ld.so.conf';

# ------------------------------------------------------------------------------
sub exec_with_llp
{
    my ( $exe, @argv ) = @_;
    my @dirs;
    _parse_ld_file( \@dirs, $LD_SO_CONF );
    $ENV{LD_LIBRARY_PATH} = join q{:}, @dirs;
    return exec $exe, @argv;
}

# ------------------------------------------------------------------------------
sub _parse_ld_file
{
    my ( $dirs, $path ) = @_;

    my @lines = path($path)->lines;
    for( @lines ) {
        my @parts = split /\s+/sm;
        ( @parts == 0 || @parts > 2 || $parts[0] =~ /^#/ ) and next;
        if( @parts == 1 ) {
            any { $parts[0] eq $_ } @{$dirs} or push @{$dirs}, $parts[0];
        }
        elsif ( $parts[0] =~ /^Include$/ism ) {
            my @files = glob $parts[1];
            _parse_ld_file( $dirs, $_ ) for @files;
        }
    }
    return $dirs;
}

# ------------------------------------------------------------------------------
1;
__END__


=head1 SYNOPSIS

    BEGIN {
        $ENV{LD_LIBRARY_PATH} or exec_with_llp( $PROGRAM_NAME, @ARGV );
    }

=cut

# ------------------------------------------------------------------------------
