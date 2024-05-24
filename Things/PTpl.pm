package Things::PTpl;

# ------------------------------------------------------------------------------
use strict;
use warnings;
use English qw/-no_match_vars/;
use self;

# ------------------------------------------------------------------------------
use Eval::Context;
use HTML::Parser;
use Path::Tiny;
use Try::Catch;

use Things::Xargs;

our %TPL_VARS;

use base qw/Exporter/;
our @EXPORT = qw/%TPL_VARS/;

use DDP;

# ------------------------------------------------------------------------------
sub new
{
    $self = bless {}, $self;
    $self->{opt_} = selfopt( $self, @args );
    $self->{error} and return $self;

    $self->{opt_}->{path} //= q{.};
    $self->{opt_}->{path} .= q{/};

    $self->{TRX} = qr/(\$TPL_VARS(\{\S+\}(\S{0,}[\]\}])?))/sm;

    $self->{CTX} = Eval::Context->new(
        PRE_CODE     => "use strict;\nuse warnings;use Things::PTpl;\n",
        INSTALL_SUBS => { 'pf' => sub { $self->pf(@_) } },
    );
    %TPL_VARS = %{ $self->{opt_}->{vars} };

    return $self;
}

# ------------------------------------------------------------------------------
sub _get_parser
{
    my $p = HTML::Parser->new();
    $p->unbroken_text(1);
    $p->handler(
        text => sub {

            my ( $parser, @data ) = @_;
            if ( $parser->{ptag_} ) {
                $parser->{perl_} .= join q{}, @data;
            }
            else {
                $parser->{out_} .= _parse_text_block( $self, ( join q{}, @data ), $parser->{data_} );
            }
        },
        'self, dtext'
    );

    $p->handler(
        start => sub {

            my ( $parser, $tag, $attr ) = @_;
            if ( $tag eq 'perl' ) {
                $parser->{ptag_} = 1;
            }
            elsif ($attr) {
                $parser->{out_} .= sprintf '<%s', $tag;
                for ( sort keys %{$attr} ) {
                    $_ eq '/' and next;
                    $parser->{out_} .= sprintf( ' %s="%s"',
                        _parse_text_block( $self, $_,          $parser->{data_} ),
                        _parse_text_block( $self, $attr->{$_}, $parser->{data_} ) );
                }
                exists $attr->{'/'} and $parser->{out_} .= '/';
                $parser->{out_} .= '>';
            }
            else {
                $parser->{out_} .= sprintf '<%s>', $tag;
            }
        },
        'self, tagname, attr'
    );

    $p->handler(
        end => sub {

            my ( $parser, $tag ) = @_;
            if ( $tag eq 'perl' ) {
                if ( $parser->{perl_} ) {
                    $parser->{out_} .= _parse_perl_block( $self, $parser->{perl_}, $parser->{data_} );
                    undef $parser->{perl_};
                    undef $parser->{ptag_};
                }
            }
            else {
                $parser->{out_} .= sprintf '</%s>', $tag;
            }
        },
        'self, tagname'
    );

    return $p;
}

# ------------------------------------------------------------------------------
sub _parse_perl_block
{
    my ( $perl, $data ) = @args;
    my $rc;

    try {
        $rc = $self->{CTX}->eval( CODE => $perl, );
    }
    catch {
        p $_;
        ...
    };
    return $rc // q{};
}

# ------------------------------------------------------------------------------
sub _parse_text_block
{
    my ( $text, $data ) = @args;

    while ( my ( $k, $v ) = each %{$data} ) {
        $text =~ s/\$$k\$/$v/gsm;
    }
    $text =~ s/\$ENV\{([^}]+)\}/$ENV{$1}/gsm;

    my @rc;
    while ( $text =~ /$self->{TRX}/g ) {
        try {
            my $xxx = eval "\$TPL_VARS$2";
            push @rc, $xxx // q{};
        }
        catch {
            ...
        };
    }

    while ( @rc && $text =~ /$self->{TRX}/g ) {
        my $xxx = shift @rc;
        $text =~ s/$self->{TRX}/$xxx/sm;
    }

    return $text;
}

# ------------------------------------------------------------------------------
sub pt
{
    my ( $text, %data ) = @args;

    my $p = $self->_get_parser();
    $p->{perl_} = undef;
    $p->{ptag_} = undef;
    $p->{data_} = \%data;
    $p->{out_}  = q{};
    $p->parse($text);
    $p->eof;
    return $p->{out_};
}

# ------------------------------------------------------------------------------
sub pf
{
    my ( $file, %data ) = @args;
    return $self->pt( path( $self->{opt_}->{path} . $file )->slurp_utf8, %data );
}

# ------------------------------------------------------------------------------
1;
__END__

