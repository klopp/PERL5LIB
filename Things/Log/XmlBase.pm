package Things::Log::XmlBase;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use XML::Hash::XS;

use Exporter qw/import/;
our @EXPORT = qw/get_xml to_xml/;

our $VERSION = 'v1.10';
# ------------------------------------------------------------------------------
sub get_xml
{
    my ($logger) = @_;
    $logger->{xml_}              = $logger->{xml};
    $logger->{xml_}->{xml_decl}  = 0;
    $logger->{xml_}->{canonical} = 1;
    $logger->{xml_}->{root} ||= 'log';
    delete $logger->{xml};
    return $logger;
}

# ------------------------------------------------------------------------------
sub to_xml
{
    my ( $msg, $logger ) = @_;
    $msg = $logger->{split_}
        ? hash2xml $logger->{log_}, %{ $logger->{xml_} }
        : hash2xml { $logger->{caption_} => $msg },
        %{ $logger->{xml_} };
    return $msg;
}

# ------------------------------------------------------------------------------
1;
__END__
