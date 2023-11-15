package Things::InlineC;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use File::Path qw/make_path/;
use File::Spec;

my $inline_temp;
BEGIN {
    use File::Path qw/make_path/;
    use File::Spec;
    ( $inline_temp = __PACKAGE__ ) =~ s/::/\//smg;
    $inline_temp = File::Spec->tmpdir() . '/.' . $inline_temp;
    make_path $inline_temp;
}

use Inline C => Config => 
    directory => $inline_temp,
    ccflags   => '-Wall -pedantic -pedantic-errors -Wextra';

# ------------------------------------------------------------------------------
1;
