package Things::OnvifC;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use base qw/Exporter/;
our @EXPORT = qw/get_cap_uri get_stream_uri cam_reboot get_onvif_error/;

use Things::Inline;
use Inline Things::Inline::c_config;
use Inline C => Config => libs => '-lonvif -lxml2', ccflags => '-I/usr/include/libxml2';
use Inline C => <<'...';
 
#include <string.h>
#include <onvif.h>

char onvif_error[1024];
char onvif_uri[1024];

const char * get_onvif_error()
{
    return onvif_error;
}

int _onvif_init( struct OnvifSession * onvif_session, struct OnvifData * onvif_data, 
            const char * user, const char * password, const char * addr ) {

    *onvif_error = 0;
    initializeSession( onvif_session );
    strcpy( onvif_data->username, user ? user : "" );
    strcpy( onvif_data->password, password ? password : "" );
    strcpy( onvif_data->xaddrs, addr );
    strcpy( onvif_data->device_service, onvif_data->xaddrs );
    extractOnvifService(onvif_data->device_service, true);
    strcpy( onvif_data->profileToken, "PROFILE_000" );
    int rc = getCapabilities( onvif_data );
    if( rc ) {
        strcpy( onvif_error, onvif_data->last_error );        
    }
    return rc;           
}

/*
int get_device_info( const char * user, const char * password, const char * addr ) 
{
    struct OnvifSession onvif_session = { 0 };
    struct OnvifData onvif_data = { 0 };

    int rc = _onvif_init( &onvif_session, &onvif_data, user, password, addr );
    if( !rc ) {
        rc = getDeviceInformation( &onvif_data );
        if( rc ) {
            strcpy( onvif_error, onvif_data.last_error );        
        }
    }

    closeSession( &onvif_session );
    return rc;
}
*/


const char * get_cap_uri( const char * user, const char * password, const char * addr ) 
{
    struct OnvifSession onvif_session = { 0 };
    struct OnvifData onvif_data = { 0 };

    *onvif_uri = 0;
    int rc = _onvif_init( &onvif_session, &onvif_data, user, password, addr );
    if( !rc ) {
        rc = getSnapshotUri( &onvif_data );
        if( !rc ) {
            strcpy( onvif_uri, onvif_data.snapshot_uri );
        }
        else {
            *onvif_uri = 0;
            strcpy( onvif_error, onvif_data.last_error );        
        }
    }

    closeSession( &onvif_session );
    return *onvif_uri ? onvif_uri : NULL;
}

const char * get_stream_uri( const char * user, const char * password, const char * addr ) 
{
    struct OnvifSession onvif_session = { 0 };
    struct OnvifData onvif_data = { 0 };

    *onvif_uri = 0;
    int rc = _onvif_init( &onvif_session, &onvif_data, user, password, addr );
    if( !rc ) {
        rc = getStreamUri( &onvif_data );
        if( !rc ) {
            strcpy( onvif_uri, onvif_data.stream_uri );
        }
        else {
            *onvif_uri = 0;
            strcpy( onvif_error, onvif_data.last_error );        
        }
    }

    closeSession( &onvif_session );
    return *onvif_uri ? onvif_uri : NULL;
}

int cam_reboot( const char * user, const char * password, const char * addr ) 
{
    struct OnvifSession onvif_session = { 0 };
    struct OnvifData onvif_data = { 0 };
    int rc = _onvif_init( &onvif_session, &onvif_data, user, password, addr );
    if( !rc ) {
        rc = rebootCamera( &onvif_data );
        if( rc ) {
            strcpy( onvif_error, onvif_data.last_error );        
        }
    }
    closeSession( &onvif_session );
    return rc;
}

/*
int get_network_interfaces( const char * user, const char * password, const char * addr )
{
    struct OnvifSession onvif_session = { 0 };
    struct OnvifData onvif_data = { 0 };
//    static char uri[1024];
    *onvif_uri = 0;
    int rc = _onvif_init( &onvif_session, &onvif_data, user, password, addr );
    if( !rc ) {
        rc = getNetworkInterfaces( &onvif_data );
        if( rc ) {
            strcpy( onvif_error, onvif_data.last_error );        
        }
        else {
            *onvif_uri = 0;
            strcpy( uri, onvif_data.ip_address_buf );
        }
    }
    closeSession( &onvif_session );
    return *onvif_uri ? onvif_uri : NULL;
}
*/

...
 
# ------------------------------------------------------------------------------
1;
__END__

