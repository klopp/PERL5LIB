package Things::Inotify;

# ------------------------------------------------------------------------------
use threads;
use threads::shared;

#use DDP;

# ------------------------------------------------------------------------------
use utf8::all;
use open qw/:std :utf8/;
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Array::Utils qw/array_minus/;
use Const::Fast;
use Switch;

use File::Which;
use IPC::Open2;
use Time::HiRes qw/usleep/;
use Time::Local qw/timelocal_posix/;
use Time::Out qw/timeout/;

use Things::Bool;
use Things::Const qw/:types/;
use Things::Xargs;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.05';

const my @ALL_EVENTS => qw/
    access modify attrib
    close_write close_nowrite close
    open create delete delete_self
    move moved_to moved_from move_self
    unmount
    /;
const my $DEF_TIMEOUT => 10;              # 10 sec
const my $DEF_SLEEP   => 1000;            # 1 sec
const my $I_BIN       => 'inotifywait';
const my $I_CMD       =>
    '%s -q -m __I_REC__ __I_MOD__ __I_EVT__ --timefmt="%%Y-%%m-%%d %%X" --format="%%T %%w%%f [%%e]" "__I_DIR__"';
const my $RX_DATE => '(\d{4})[-](\d\d)[-](\d\d)';
const my $RX_TIME => '(\d\d):(\d\d):(\d\d)';

# ------------------------------------------------------------------------------
## no critic (RequireArgUnpacking)
sub new
{
    my $class = shift;

    my $self = bless {}, $class;
    ( $self, my $opt ) = selfopt( $self, @_ );
    $self->{error} and return $self;

    $self->{inotify} = which $I_BIN;
    if ( !$self->{inotify} ) {
        $self->{error} = sprintf 'No required "%s" executable found!', $I_BIN;
        return $self;
    }

    $self->{events}  = $self->{recurse} = q{};
    $self->{timeout} = $DEF_TIMEOUT;
    $self->{sleep}   = $DEF_SLEEP;

    while ( my ( $key, $value ) = each %{$opt} ) {
        switch ($key) {
            case /^dir$/i     { $self->_parse_dir($value)     or return $self; }
            case /^mode$/i    { $self->_parse_mode($value)    or return $self; }
            case /^events$/i  { $self->_parse_events($value)  or return $self; }
            case /^recurse$/i { $self->_parse_recurse($value) or return $self; }
            $self->{error} = sprintf 'Unknown parameter "%s"', $key;
            return $self;
        }
    }

    $self->_check_param('dir') and $self->_check_param('mode');
    return $self;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;

    my $icmd = sprintf $I_CMD, $self->{inotify};
    $icmd =~ s/__I_DIR__/$self->{dir}/gsm;
    $icmd =~ s/__I_EVT__/$self->{events}/gsm;
    $icmd =~ s/__I_MOD__/$self->{mode}/gsm;
    $icmd =~ s/__I_REC__/$self->{recurse}/gsm;

    my $ipid = open2( my $stdout, undef, $icmd );

    $self->{events_data} = &share( [] );

    threads->new(
        sub {
            use sigtrap 'handler' => sub { threads->exit }, qw/normal-signals error-signals USR1 USR2/;
            use sigtrap 'handler' => sub { }, 'ALRM';

            while (1) {
                while ( $_ = timeout $self->{timeout} => sub { $stdout->getline } ) {
                    if (m{^
            $RX_DATE
            \s+
            $RX_TIME
            \s+
            (.*)
            \s+
            \[(.+)\]
        }xsm
                        )
                    {
                        lock( $self->{events_data} );
                        my $data = &share( {} );
                        push @{ $self->{events_data} }, $data;
                        $data->{path}   = $7;
                        $data->{events} = $8;
                        $data->{tstamp} = timelocal_posix( $6, $5, $4, $3, $2 - 1, $1 - 1900 );
                    }
                }
            }
        }
    )->detach;
}

# ------------------------------------------------------------------------------
sub has_events
{
    my ($self) = @_;
    return scalar @{ $self->{events_data} };
}

# ------------------------------------------------------------------------------
sub wait_for_events
{
    my ($self) = @_;
    
    while ( !@{ $self->{events_data} } ) {
        usleep $self->{sleep};
    }
    lock( @{ $self->{events_data} } );

    my @events;
    while ( @{ $self->{events_data} } ) {
        push @events, pop @{ $self->{events_data} };
    }
    return @events;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    threads->exit;
}

# ------------------------------------------------------------------------------
sub _invalid_param
{
    my ( $self, $param ) = @_;
    $self->{error} = sprintf 'Invalid parameter "%s"', $param;
    return;
}

# ------------------------------------------------------------------------------
sub _no_param
{
    my ( $self, $param ) = @_;
    $self->{error} = sprintf 'No required parameter "%s"', $param;
    return;
}

# ------------------------------------------------------------------------------
sub _check_param
{
    my ( $self, $param ) = @_;
    $self->{$param} or return $self->_no_param($param);
    return $self;
}

# ------------------------------------------------------------------------------
sub _parse_dir
{
    my ( $self, $dir ) = @_;
    -d $dir or return $self->_invalid_param('dir');
    $self->{dir} = $dir;
    return $self;
}

# ------------------------------------------------------------------------------
sub _parse_mode
{
    my ( $self, $mode ) = @_;

    if ( $mode =~ /^i|inotify$/i ) {
        $self->{mode} = '-I';
    }
    elsif ( $mode =~ /^f|fanotify$/i ) {
        $self->{mode} = '-F';
    }
    else {
        return $self->_invalid_param('mode');
    }
    return $self;
}

# ------------------------------------------------------------------------------
sub _parse_recurse
{
    my ( $self, $recurse ) = @_;
    $self->{recurse} = parse_bool($recurse) ? '-r' : q{};
    return $self;
}

# ------------------------------------------------------------------------------
sub _parse_events
{
    my ( $self, $inevents ) = @_;

    my @events;
    if ( ref $inevents eq $ARRAY ) {
        @events = map {lc} @{$inevents};
    }
    elsif ( !ref $inevents ) {
        @events = map {lc} split /[,\s]+/, $inevents;
    }
    else {
        return $self->_param_error('events');
    }

    if (@events) {
        array_minus( @events, @ALL_EVENTS ) and return $self->_param_error('events');
    }
    else {
        @events = @ALL_EVENTS;
    }

    $self->{events} = join q{ }, map {"-e $_"} @events;
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__
