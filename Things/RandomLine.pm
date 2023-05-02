package Things::RandomLine;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/random_line/;
our $VERSION = 'v1.0';

use Things::Trim;

# ------------------------------------------------------------------------------
sub random_line
{
    my ( $filename, $noempty ) = @_;

    open my $fh, '<', $filename
        or Carp::confess sprintf 'Can not open file "%s" in "%s()"', $filename, ( caller 1 )[0];
    my $filesize = -s $filename;
    seek( $fh, int( rand $filesize ), 0 );
    <$fh>;
    seek( $fh, 0, 0 ) if eof $fh;
    my $line = trim(<$fh>);

    while ($noempty) {
        last if $line;
        $line = (<$fh>);
        seek( $fh, 0, 0 ) if eof $fh;
    }
    close $fh;
    return $line;
}

# ------------------------------------------------------------------------------
1;
