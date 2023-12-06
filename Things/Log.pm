package Things::Log;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
use parent qw/Exporter/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $module, @params ) = @_;
    $module =~ /^$class/sm or $module = sprintf '%s::%s', $class, $module;

    if ( !$module->can('new') ) {
        ( my $modfile = $module . '.pm' ) =~ s{::}{/}gsm;
        eval { require $modfile; 1; } or Carp::confess $EVAL_ERROR;
    }
    my $self = $module->new(@params);
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

    my $log = Things::Log->new( 'File', file => '/var/log/my.log' );
    $log->info(...);

=cut

