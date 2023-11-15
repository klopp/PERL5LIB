package Things::Inline;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Const::Fast;
use File::Path qw/make_path/;
use File::Spec;

const my $CCFLAGS => '-Wall -pedantic -pedantic-errors -Wextra';

# ------------------------------------------------------------------------------
sub config
{
    ( my $inline_temp = ( ( caller 1 )[0] || __PACKAGE__ ) ) =~ s/::/\//smg;
    $inline_temp = File::Spec->tmpdir() . '/.' . $inline_temp;
    make_path $inline_temp;

    my @config = ( 'Config', directory => $inline_temp, );

    return @config;
}

# ------------------------------------------------------------------------------
sub c_config
{
    my @config = (
        C       => config,
        ccflags => $CCFLAGS,
    );

    return @config;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    use Things::Inline;
    use Inline Things::Inline::c_config;
    # OR
    use Things::Inline;
    use Inline Things::Inline::c_config;

=cut

# ------------------------------------------------------------------------------
