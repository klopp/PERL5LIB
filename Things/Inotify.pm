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
use Try::Catch;

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
const my $I_CMD       => '%s -q -m __I_REC__ __I_MOD__ __I_EVT__ __I_SYM__ '
    . '--timefmt="%%Y-%%m-%%d %%X" ' . '--format="%%T %%w%%f [%%e]" "__I_PATH__"';
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

    $self->{events}  = $self->{recurse} = $self->{symlinks} = q{};
    $self->{read_to} = $DEF_READ_TO;
    $self->{poll_to} = $DEF_POLL_TO;

    CORE::state %param_handlers = (
        path     => sub { $self->_parse_path(shift); },
        mode     => sub { $self->_parse_mode(shift); },
        events   => sub { $self->_parse_events(shift); },
        recurse  => sub { $self->{recurse} = shift ? '-r' : q{}; },
        read_to  => sub { $self->_parse_to( shift, 'read_to' ); },
        poll_to  => sub { $self->_parse_to( shift, 'poll_to' ); },
        symlinks => sub { $self->{symlinks} = shift ? q{} : '-P'; },
        _        => sub {
            $self->{error} = sprintf 'Unknown parameter "%s".', shift;
        },
    );

    while ( my ( $key, $value ) = each %{$opt} ) {
        $key = lc $key;
        $param_handlers{$key} ? $param_handlers{$key}->($value) : $param_handlers{_}->($key);
        $self->{error} and last;
    }
    $self->{poll_to} *= 1000;

    $self->{error} or ( $self->_check_param('path') and $self->_check_param('mode') );
    return $self;
}

# ------------------------------------------------------------------------------
sub run
{
    my ($self) = @_;

    my $icmd = sprintf $I_CMD, $self->{inotify};
    $icmd =~ s/__I_PATH__/$self->{path}/gsm;
    $icmd =~ s/__I_SYM__/$self->{symlinks}/gsm;
    $icmd =~ s/__I_MOD__/$self->{mode}/gsm;
    $icmd =~ s/__I_EVT__/$self->{events}/gsm;
    $icmd =~ s/__I_REC__/$self->{recurse}/gsm;

    my $stdout;
    try {
        $self->{ipid} = open2( $stdout, undef, $icmd . 'z' );
    }
    catch {
        $self->{error} = $_;
    };
    return if $self->{error};

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
sub error
{
    my ($self) = @_;
    return $self->{error};
}

# ------------------------------------------------------------------------------
sub has_events
{
    my ($self) = @_;
    return if $self->{error} || !$self->{ipid};
    return scalar @{ $self->{events_data} };
}

# ------------------------------------------------------------------------------
sub wait_for_events
{
    my ($self) = @_;
    return if $self->{error} || !$self->{ipid};

    while ( !@{ $self->{events_data} } ) {
        usleep $self->{poll_to};
    }

    lock @{ $self->{events_data} };
    my @events;
    while ( @{ $self->{events_data} } ) {
        push @events, shift @{ $self->{events_data} };
    }
    return wantarray ? @events : \@events;
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
    if ( $to =~ /^\d+$/sm && $to > 0 ) {
        $self->{$param} = $to;
        return $self;
    }
    return $self->_invalid_param($param);
}

# ------------------------------------------------------------------------------
sub _parse_path
{
    my ( $self, $path ) = @_;
    -e $path or return $self->_invalid_param('path');
    $self->{path} = $path;
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

=head1 DESCRIPTION

Watch for changes to files and directories using L<inotifywait|https://manpages.org/inotifywait>.

=head1 SYNOPSIS

    my $watcher = Things::Inotify->new( path => '/tmp', mode => 'i' );
    $watcher->run;
    while( my @events = $whatcher->wait_for_events ) {
        for( @events ) {
            say $_->{path};
            say $_->{is_dir};
            say $_->{tstamp};
            say join q{,}, @{$_->{events});
        }
    } 

=head1 CONFIGURATION AND ENVIRONMENT

    my $whatcher = Things::Inotify->new( HASH );

OR

    my $whatcher = Things::Inotify->new( HASH REF );

=head2 Required C<new> arguments:

=over

=item C<path>

Path to watch.

=item C<mode>

Use C<inotify> (C<i>) or C<fanotify> (C<f>).

=back 

=head2 Optional C<new> arguments:

=over

=item C<events>

=item C<symlinks>

=item C<recurse>

=item C<read_to>

=item C<poll_to>

=back 

=head1 SUBROUTINES/METHODS

=over

=item run()

Start watching.

=item error()

Get last error string.

=item list_events()

Return array or array ref with valid event names. Call anytime, as object method or without object.

=item has_events()

Return number of events available, use after C<run()>. 

=item wait_for_events()

Block watcher until it sees events, and then return them as a list or list reference.

=back

=head1 DIAGNOSTICS

C<Things::Inotify::error()> method return last error string or C<undef>.


=head1 DEPENDENCIES 

=over

=item L<Array::Utils>

=item L<Const::Fast>

=item L<File::Which>

=item L<IPC::Open2>

=item L<POSIX>

=item L<Proc::Killfam>

=item L<Time::HiRes>

=item L<Time::Local>

=item L<Time::Out>

=item L<Try::Catch>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Vsevolod Lutovinov.

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself. The full text of this license can be found in 
the LICENSE file included with this module.

=head1 AUTHOR

Contact the author at kloppspb@bk.ru
