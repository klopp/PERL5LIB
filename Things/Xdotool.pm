package Things::Xdotool;

# ------------------------------------------------------------------------------
use utf8::all;
use open qw/:std :utf8/;
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Const::Fast;
use File::Which;
use IPC::Run qw/run timeout/;
use Try::Catch;

use Things::Const qw/:types/;
use Things::Trim;

use DDP;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/xdotool/;
our $VERSION = 'v1.0';

const my $TIMEOUT_DEF => 2;
 
# ------------------------------------------------------------------------------
sub xdotool
{
    my (@args) = @_;

    CORE::state $xdotool;
    
    $xdotool or $xdotool = which 'xdotool';
    $xdotool or Carp::confess 'Can not find "xdotool" executable';

    my $timeout = $TIMEOUT_DEF;
    for (@args) {
        if ( ref $_ eq $HASH ) {
            $timeout = trim( $_->{timeout} ) || q{?};
            $timeout =~ /^\d+$/sm or 
                Carp::confess 
                    sprintf '%s() :: invalid "timeout" parameter', ( caller 0 )[3];
            undef $_;
        }
    }

    my $stdout;
    try {
        run [ $xdotool, grep { defined } @args ], sub { }, \$stdout, sub { }, timeout($timeout);
    }
    catch {
        undef $stdout;
    };
    return $stdout;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 DESCRIPTION

L<xdotool|https://manpages.org/xdotool> wrapper.

=head1 SYNOPSIS

    my $active_window_name = xdotool( 'getwindowfocus', 'getwindowname', { timeout => 2 } );

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Vsevolod Lutovinov.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. The full text of this license can be found in 
the LICENSE file included with this module.

=head1 AUTHOR

Contact the author at kloppspb@bk.ru
