package Things::Config::Find;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Const::Fast;
use English qw/-no_match_vars/;
use File::Basename qw/fileparse/;

const my $EXT_NO   => q{};
const my $EXT_RC   => '.rc';
const my $EXT_CONF => '.conf';

my @tested_files;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub find
{
    my ( $name, $path ) = fileparse($PROGRAM_NAME);
    $name =~ s/^(.+)[.][^.]+$/$1/gsm;
    undef @tested_files;
    my $file;
    $ENV{XDG_CONFIG_HOME}
        and $file = _test_location( $name, $ENV{XDG_CONFIG_HOME}, $EXT_NO, $EXT_CONF, $EXT_RC );
    $file or $file = _test_location( $name, $ENV{HOME} . q{/.},        $EXT_NO,   $EXT_CONF, $EXT_RC );
    $file or $file = _test_location( $name, $ENV{HOME} . '/.config/', $EXT_NO,   $EXT_CONF, $EXT_RC );
    $file or $file = _test_location( $name, $path,                    $EXT_CONF, $EXT_RC );
    $file or $file = _test_location( $name, '/etc/',                  $EXT_CONF, $EXT_RC );
    $file or $file = _test_location( $name, '/etc/default/',          $EXT_NO );
    return $file;
}

# ------------------------------------------------------------------------------
sub tested_files
{
    return wantarray ? @tested_files : \@tested_files;
}

# ------------------------------------------------------------------------------
sub _test_location
{
    my ( $name, $location, @ext ) = @_;
    for (@ext) {
        my $filename = sprintf '%s%s%s', $location, $name, $_;
        push @tested_files, $filename;
        return $filename if -T $filename;
    }
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

