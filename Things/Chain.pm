package Things::Chain;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use self;

# ------------------------------------------------------------------------------
our $AUTOLOAD;
our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    $self = bless { chain_ => [] }, $self;
    push @{ $self->{chain_} }, $_ for @args;
    return $self;
}

# ------------------------------------------------------------------------------
sub add
{
    push @{ $self->{chain_} }, @args;
    return $self;
}

# ------------------------------------------------------------------------------
sub AUTOLOAD
{
    ( my $method = $AUTOLOAD ) =~ s/.*:://gsm;

    {
        no strict 'refs';
        *{$AUTOLOAD} = sub {
            shift;
            $_->can($method) and $_->$method(@_) for @{ $self->{chain_} };
        };
    }

    return $self->$method(@args);
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    return $self;
}

# ------------------------------------------------------------------------------
1;
__END__

=head1 SYNOPSIS

    my $log_chain = Things::Chain->new;
    $log_chain->add( Things::Log::Std->new );
    OR
    my $log_chain = Things::Chain->new( $file_logger, $mysql_logger ...);

=cut

# ------------------------------------------------------------------------------
