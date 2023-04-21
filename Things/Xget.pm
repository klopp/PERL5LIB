package Things::Xget;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use base qw/Exporter/;
our @EXPORT  = qw/xget/;
our $VERSION = 'v1.0';

use lib q{.};
use Things::Const qw/:types/;
use Things::Trim;

# ------------------------------------------------------------------------------
sub xget
{
    my ( $src, $path ) = @_;

=for comment
    my $data = { a => [ 0, 1, 2, { b => 'c' } ] };
    #
    # "3" может быть индексом ARRAY или ключом HASH:
    my $rc = xget( $data, '/a/3/b' );
    #
    # ИЛИ
    #
    # "3" - только индекс (проверяем что ref $src->{a} eq 'ARRAY'):
    my $rc = xget( $data, '/a/[3]/b' );
    # В обоих случаях получили 'c'.
=cut    

    my @parts  = grep {$_} trim( split( '/', $path ) );
    my $cursor = $src;

    for (@parts) {
        if (/^\[(\d+)\]$/) {
            return if ref $cursor ne $ARRAY;
            return unless exists $cursor->[$1];
            $cursor = $cursor->[$1];
        }
        elsif ( ref $cursor eq $HASH ) {
            return unless exists $cursor->{$_};
            $cursor = $cursor->{$_};
        }
        elsif ( ref $cursor eq $ARRAY ) {
            return unless /^(\d+)$/;
            return unless exists $cursor->[$1];
            $cursor = $cursor->[$1];
        }
        else {
            return;
        }
    }
    return $cursor;
}

# ------------------------------------------------------------------------------
1;
