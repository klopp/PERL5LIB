package Things::IP;

use base qw/Exporter/;
our @EXPORT  = qw/ip2long long2ip/;
our $VERSION = 'v1.0';

use Socket qw/inet_aton inet_ntoa/;

# ------------------------------------------------------------------------------
sub ip2long
{
    my ($ip) = @_;
    return unpack( 'l*', pack( 'l*', unpack( 'N*', inet_aton($ip) ) ) );
}

# ------------------------------------------------------------------------------
sub long2ip
{
    my ($ip) = @_;
    return inet_ntoa( pack( 'N*', $ip ) );
}

# ------------------------------------------------------------------------------
1;
