package Things::Log;

# ------------------------------------------------------------------------------
use strict;
use warnings;

# ------------------------------------------------------------------------------
use English qw/-no_match_vars/;
use parent qw/Exporter/;

# ------------------------------------------------------------------------------
our $log;
our @EXPORT  = qw/$log/;
our $VERSION = '1.00';

# ------------------------------------------------------------------------------
sub import
{
    my ( $self, $module, @params ) = @_;
    if ( !$module ) {
        Carp::confess sprintf "use %s %s::MODULE [, \@params];\n", $self, $self;
    }
    $module =~ /^$self/ or $module = sprintf '%s::%s', $self, $module;

    if ( !$module->can('new') ) {
        ( my $modfile = $module . '.pm' ) =~ s|::|/|gsm;
        eval { require $modfile; };
        $EVAL_ERROR and Carp::confess $EVAL_ERROR;
    }
    $log = $module->new(@params);
    $self->export_to_level( 1, $self, qw/$log/ );
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    use Things::Log 'File', file => '/var/log/my.log';
    $log->info(...);

=cut

