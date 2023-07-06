package Things::Log::Redis;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Redis::Fast;

use Things::Log::CsvBase;
use Things::Log::JsonBase;
use Things::Log::XmlBase;
use Things::Log::Base;
use base qw/Things::Log::Base/;

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    $self->{redis_}  = Redis::Fast->new( $self->{redis} );
    $self->{format_} = lc $self->{format};
    delete $self->{format};
    delete $self->{redis};
    $self->{format_} eq 'csv'  and get_csv($self);
    $self->{format_} eq 'json' and get_json($self);
    $self->{format_} eq 'xml'  and get_xml($self);
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    $self->{format_} eq 'csv'  and $msg = to_csv( $msg, $self );
    $self->{format_} eq 'json' and $msg = to_json( $msg, $self );
    $self->{format_} eq 'xml'  and $msg = to_xml( $msg, $self );
    $self->{redis_}->lpush( 'message', $msg );
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Redis->new(  );

=cut

# ------------------------------------------------------------------------------
