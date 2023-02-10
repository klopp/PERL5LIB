package Things::Autoload;

# ------------------------------------------------------------------------------
our $AUTOLOAD;

#------------------------------------------------------------------------------
sub get_object
{
    my ($self) = @_;
    return $self;
}

#------------------------------------------------------------------------------
sub AUTOLOAD
{
    my ( $self, @args ) = @_;

    $AUTOLOAD =~ s/^.*:://gsm;
    my $object = $self->get_object;
    my $class  = ref $self;
    {
        no strict 'refs';
        *{ $class . '::' . $AUTOLOAD } = sub { shift; return $object->$AUTOLOAD(@_); };
    }
    return $object->$AUTOLOAD(@args);
}

# ------------------------------------------------------------------------------
1;
__END__
