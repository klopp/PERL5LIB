package Things::Log::Code;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

use Things::Const qw/:types/;
use Things::Log::Base;
use base qw/Things::Log::Base/;

# ------------------------------------------------------------------------------
our $VERSION = 'v1.00';

# ------------------------------------------------------------------------------
sub new
{
    $self = $self->SUPER::new(@args);
    my $coderef = $self->{code} || $self->{coderef};
    if ( !$coderef ) {
        $self->{error} = 'No required "code" ("coderef") parameter.';
        return $self;
    }
    if ( ref $coderef ne $CODE ) {
        $self->{error} = 'Parameter "code" ("coderef") must be CODE ref.';
        return $self;
    }
    $self->{code_} = $coderef;
    delete $self->{code};
    return $self;
}

# ------------------------------------------------------------------------------
sub plog
{
    my ($msg) = @args;
    $self->{code_} and $self->{code_}->( $msg, $self );
    return $self;
}

# ------------------------------------------------------------------------------

1;
__END__

=head1 SYNOPSIS

    my $logger = Things::Log::Code->new( code = sub {} );

=cut

# ------------------------------------------------------------------------------
