package Things::Log::Mongo;

# ------------------------------------------------------------------------------
# Useless module.
# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Const::Fast;
use MongoDB;
use Try::Catch;

use Things::Log::CsvBase;
use Things::Log::JsonBase;
use Things::Log::XmlBase;
use Things::Log::Base;
use base qw/Things::Log::Base/;

const my $MONGO_SCHEME => 'mongodb://';

our $VERSION = 'v1.10';

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);

    my $host      = $self->{mongo}->{uri}       || $self->{mongo}->{host};
    my $namespace = $self->{mongo}->{namespace} || $self->{mongo}->{ns};
    if ( !$host ) {
        $self->{error} = 'No required "uri" ("host") in MongoDB options.';
        return $self;
    }
    if ( !$namespace ) {
        $self->{error} = 'No required "namespace" ("ns") in MongoDB options.';
        return $self;
    }
    if ( $namespace !~ /^\w+[.]\w+$/sm ) {
        $self->{error} = 'Invalid "namespace" ("ns") in MongoDB options.';
        return $self;
    }
    delete $self->{mongo}->{namespace};
    delete $self->{mongo}->{ns};
    delete $self->{mongo}->{host};
    delete $self->{mongo}->{uri};
    $host =~ s/^$MONGO_SCHEME//gsm;
    try {
        $self->{mongo_} = MongoDB->connect( $MONGO_SCHEME . $host, $self->{mongo} )->ns($namespace);
        delete $self->{mongo};
        $self->{format} = lc $self->{format};
        $self->{format} eq 'csv'  and get_csv($self);
        $self->{format} eq 'json' and get_json($self);
        $self->{format} eq 'xml'  and get_xml($self);
    }
    catch {
        undef $self->{mongo_};
        $self->{error} = $_;
    };
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;

    if ( $self->{mongo_} ) {
        $self->{format} eq 'csv'  and $msg = to_csv( $msg, $self );
        $self->{format} eq 'json' and $msg = to_json( $msg, $self );
        $self->{format} eq 'xml'  and $msg = to_xml( $msg, $self );
        try {
            $self->{mongo_}->insert_one( [ $self->{caption_}, $msg ] );
        }
        catch {
            $self->{error} = $_;
        };
    }
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Mongo->new( uri => ..., ns => ..., { key => value, ...} );

=cut

# ------------------------------------------------------------------------------
