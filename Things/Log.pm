package Things::Log;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
use parent qw/Exporter/;

# ------------------------------------------------------------------------------
use vars qw/$log @EXPORT $VERSION/;
$VERSION = 'v1.00';
#@EXPORT  = qw/$log/;

# ------------------------------------------------------------------------------
=pod
sub import
{
    my ( $self, $module, @params ) = @_;

    $module or return;

    if ( !$module ) {
        Carp::confess sprintf 'use %s %s::MODULE [, @params];', $self, $self;
    }
    $module =~ /^$self/sm or $module = sprintf '%s::%s', $self, $module;

    if ( !$module->can('new') ) {
        ( my $modfile = $module . '.pm' ) =~ s{::}{/}gsm;
        eval { require $modfile; 1; } or Carp::confess $EVAL_ERROR;
    }
    $log = $module->new(@params);
    $self->export_to_level( 1, $self, qw/$log/ );
    return;
}
=cut

# ------------------------------------------------------------------------------
sub new
{
    my ($class, $module, @params ) = @_;
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
    my ( $self ) = @_;
    return $self->DESTROY;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    use Things::Log 'File', file => '/var/log/my.log';
    $log->info(...);

=cut

