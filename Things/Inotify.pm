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
use POSIX qw/:sys_wait_h/;
use Proc::Killfam;
use Time::HiRes qw/usleep/;
use Time::Local qw/timelocal_posix/;
use Time::Out qw/timeout/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.01';

const my @ALL_EVENTS => qw/
    access modify attrib unmount
    close_write close_nowrite close
    open create delete delete_self
    move moved_to moved_from move_self
    /;
const my $DEF_READ_TO => 10;
const my $DEF_POLL_TO => 500;
const my $I_BIN       => 'inotifywait';
const my $I_CMD       => '%s -q -m __I_REC__ __I_MOD__ __I_EVT__ '
    . '--timefmt="%%Y-%%m-%%d %%X" '
    . '--format="%%T %%w%%f [%%e]" "__I_DIR__"';
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

    CORE::state %param_handlers = (
        dir     => sub { $self->_parse_dir(shift); },
        mode    => sub { $self->_parse_mode(shift); },
        events  => sub { $self->_parse_events(shift); },
        recurse => sub { $self->{recurse} = shift ? '-r' : q{}; },
        read_to => sub { $self->{read_to} = $self->_parse_to( shift, 'read_to' ); },
        poll_to => sub { $self->{poll_to} = $self->_parse_to( shift, 'poll_to' ); },
        _       => sub {
            $self->{error} = sprintf 'Unknown parameter "%s".', shift;
        },
    );

    while ( my ( $key, $value ) = each %{$opt} ) {
        $key = lc $key;
        $param_handlers{$key} ? $param_handlers{$key}->($value) : $param_handlers{_}->($key);
    }
    $self->{poll_to} *= 1000;

    $self->{error} or ( $self->_check_param('dir') and $self->_check_param('mode') );
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

    $self->{ipid} = open2( my $stdout, undef, $icmd );

    $self->{events_data} = shared_clone [];
    threads->new(
        sub {
            use sigtrap 'handler' => sub { threads->exit }, qw/normal-signals error-signals USR1 USR2/;
            use sigtrap 'handler' => sub { }, 'ALRM';

            while ( $_ = timeout $self->{read_to} => sub { $stdout->getline } ) {
                next unless m{^
                                $RX_DATE
                                \s+
                                $RX_TIME
                                \s+
                                (.*)
                                \s+
                                \[(.+)\]
                            }xsm;
                my $data = shared_clone {
                    events => [],
                    is_dir => 0,
                    path   => $7,
                    tstamp => timelocal_posix( $6, $5, $4, $3, $2 - 1, $1 - 1900 ),
                };
                for ( split /[,\s]+/sm, $8 ) {
                    if ( $_ eq 'ISDIR' ) {
                        $data->{is_dir} = 1;
                    }
                    else {
                        push @{ $data->{events} }, $_;
                    }
                }
                lock $self->{events_data};
                push @{ $self->{events_data} }, $data;
            }
        }
    )->detach;
    return $self;
}

# ------------------------------------------------------------------------------
sub list_events
{
    my @events = sort @ALL_EVENTS;
    return wantarray ? @events : \@events; 
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
        push @events, shift @{ $self->{events_data} };
    }
    return @events;
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    if ( $self->{ipid} ) {
        killfam 'TERM', ( $self->{ipid} );
        while ( ( my $kidpid = waitpid -1, WNOHANG ) > 0 ) {
            sleep 1;
        }
    }
    threads->exit;
    return $self;
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
sub _parse_to
{
    my ( $self, $to, $param ) = @_;
    ( $to =~ /^\d+$/sm && $to > 0 ) and return $to;
    $self->_invalid_param($param);
    return 0;
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

    if ( $mode =~ /^i|inotify$/ism ) {
        $self->{mode} = '-I';
    }
    elsif ( $mode =~ /^f|fanotify$/ism ) {
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
        @events = map {lc} split /[,\s]+/sm, $inevents;
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

=head1 SYNOPSIS

    my $watcher = Things::Inotify->new (
        dir     => '/tmp/',       # REQUIRED
        mode    => 'i',           # REQUIRED (i, inotify OR f, fanotify)
        events  => [LIST],        # OR comma-separated values
        recurse => BOOL,
        read_to => SECONDS,
        poll_to => MILLISECONDS,
    );
    $watcher->run;
    while( my @events = $whatcher->wait_for_events ) {
        for( @events ) {
            say $_->{path};
            say $_->{is_dir};
            say $_->{tstamp};
            say join q{,}, @{$_->{events});
        }
    } 

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Vsevolod Lutovinov.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. The full text of this license can be found in 
the LICENSE file included with this module.

=head1 AUTHOR

Contact the author at kloppspb@bk.ru
