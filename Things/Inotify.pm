package Things::Inotify;

# ------------------------------------------------------------------------------
use threads;
use threads::shared;

# ------------------------------------------------------------------------------
use utf8::all;
use open qw/:std :utf8/;
use strict;
use warnings;

# ------------------------------------------------------------------------------
use Array::Utils qw/array_minus/;
use Const::Fast;
use File::Which;
use IPC::Open2;
use Switch;
use Time::HiRes qw/usleep/;
use Time::Local qw/timelocal_posix/;
use Time::Out qw/timeout/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.01';

const my @ALL_EVENTS => qw/
    access modify attrib
    close_write close_nowrite close
    open create delete delete_self
    move moved_to moved_from move_self
    unmount
    /;
const my $DEF_READ_TO => 10;              # 10 sec
const my $DEF_POLL_TO => 1000;            # 1 sec
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
    my $opt;
    if ( @_ == 1 ) {
        $opt = shift;
    }
    elsif ( @_ % 2 ) {
        return $self->_hash_required();
    }
    else {
        %{$opt} = @_;
    }

    ref $opt eq 'HASH' or return $self->_hash_required();
    $self->{inotify} = which $I_BIN;
    if ( !$self->{inotify} ) {
        $self->{error} = sprintf 'No required "%s" executable found!', $I_BIN;
        return $self;
    }

    $self->{events}  = $self->{recurse} = q{};
    $self->{read_to} = $DEF_READ_TO;
    $self->{poll_to} = $DEF_POLL_TO;

    while ( my ( $key, $value ) = each %{$opt} ) {
        switch ($key) {
            case /^dir$/i     { $self->_parse_dir($value) or return $self; }
            case /^mode$/i    { $self->_parse_mode($value) or return $self; }
            case /^events$/i  { $self->_parse_events($value) or return $self; }
            case /^recurse$/i { $self->{recurse} = $value ? '-r' : q{}; }
            $self->{error} = sprintf 'Unknown parameter "%s".', $key;
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
                while ( $_ = timeout $self->{read_to} => sub { $stdout->getline } ) {
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
                        my @events = split /[,\s]+/, $8;
                        my $data   = &share( {} );
                        $data->{is_dir} = 0;
                        $data->{events} = &share( [] );
                        for (@events) {
                            if ( $_ eq 'ISDIR' ) {
                                $data->{is_dir} = 1;
                            }
                            else {
                                push @{ $data->{events} }, $_;
                            }
                        }
                        $data->{path}   = $7;
                        $data->{tstamp} = timelocal_posix( $6, $5, $4, $3, $2 - 1, $1 - 1900 );
                        lock $self->{events_data};
                        push @{ $self->{events_data} }, $data;
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
        usleep $self->{poll_to};
    }

    lock @{ $self->{events_data} };
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
sub _hash_required
{
    my ($self) = @_;
    $self->{error} = 'HASH or HASH reference required.';
    return $self;
}

# ------------------------------------------------------------------------------
sub _invalid_param
{
    my ( $self, $param ) = @_;
    $self->{error} = sprintf 'Invalid parameter "%s".', $param;
    return;
}

# ------------------------------------------------------------------------------
sub _no_param
{
    my ( $self, $param ) = @_;
    $self->{error} = sprintf 'No required parameter "%s".', $param;
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
sub _parse_events
{
    my ( $self, $inevents ) = @_;

    my @events;
    if ( ref $inevents eq 'ARRAY' ) {
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
