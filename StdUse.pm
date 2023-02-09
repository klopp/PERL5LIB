package StdUse;

# ------------------------------------------------------------------------------
use Carp;
use Const::Fast;
use English;
use Modern::Perl;
use utf8::all;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub import
{
    Carp->import(qw/carp cluck confess croak/);
    Const::Fast->import;
    English->import(qw/-no_match_vars/);
    Modern::Perl->import;
    utf8::all->import;
    @_ = qw/open :std :utf8/;
    goto &open::import;
}

# ------------------------------------------------------------------------------
1;
__END__
