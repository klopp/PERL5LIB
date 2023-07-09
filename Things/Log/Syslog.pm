package Things::Log::Syslog;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Const::Fast;
use English qw/-no_match_vars/;
use Sys::Syslog qw/:standard :extended :macros/;
use Try::Catch;

use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
const my %SYSLOG_LEVELS => (
    'EMERG'     => LOG_EMERG,
    'EMERGENCY' => LOG_EMERG,
    'ALERT'     => LOG_ALERT,
    'CRIT'      => LOG_CRIT,
    'CRITICAL'  => LOG_CRIT,
    'ERROR'     => LOG_ERR,
    'ERR'       => LOG_ERR,
    'WARN'      => LOG_WARNING,
    'WARNING'   => LOG_WARNING,
    'NOTICE'    => LOG_NOTICE,
    'NOT'       => LOG_NOTICE,
    'INFO'      => LOG_INFO,
    'INF'       => LOG_INFO,
    'DEBUG'     => LOG_DEBUG,
    'DBG'       => LOG_DEBUG,
    'TRACE'     => LOG_DEBUG,
    'TRC'       => LOG_DEBUG,
);

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    if ( $self->{sock} ) {
        if ( !setlogsock( $self->{sock} ) ) {
            $self->{error} = $ERRNO;
            return $self;
        }
        delete $self->{sock};
    }
    try {
        openlog( $self->{ident} || q{}, $self->{logopt} || q{}, $self->{facility} || LOG_LOCAL0 );
        $self->{syslog_} = 1;
        delete $self->{indent};
        delete $self->{logopt};
        delete $self->{facility};
    }
    catch {
        $self->{error} = $_;
    };
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;
    if ( $self->{syslog_} ) {
        syslog( $SYSLOG_LEVELS{ $self->{log_}->{level} }, $msg );
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    $self->SUPER::DESTROY;
    $self->{syslog_} and closelog();
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Syslog->new( 
        socket => { type => 'tcp', port => 2486 },
        indent => 'MyIndent', 
        logopt => 'ndelay,nofatal',
        facility => LOG_LOCAL0|LOG_DAEMON 
    );

=cut

# ------------------------------------------------------------------------------
