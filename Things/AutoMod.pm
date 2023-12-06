package Things::AutoMod;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
use parent qw/Exporter/;

use DDP;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $target, @params ) = @_;

    $class =~ s/[^:]+$/$target/sm;
    if ( !$class->can('new') ) {
        ( my $modfile = $class . '.pm' ) =~ s{::}{/}gsm;
        eval { require $modfile; 1; } or Carp::confess $EVAL_ERROR;
    }
    my $self = $class->new(@params);
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    return $self->DESTROY;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $log = Things::AutoMod->new( 'Log::Std', Level => 'Debug', comments => 'True' );
    $log->info(...);

=cut

