package Example::Translator;

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);
use Locale::TextDomain 1.17 qw(example ./LocaleData);

sub new {
    my ($class, @more) = @_;

    return $class->instance(@more);
}

sub set_language {
    my ($class, $language) = @_;

    $ENV{LANGUAGE} = $language; ## no critic (LocalizedPunctuationVars)

    return $class;
}

sub get_language {
    my $class = shift;

    $ENV{LANGUAGE}
        or croak 'No language set';

    return $ENV{LANGUAGE};
}

sub translate {
    my ($class, $params) = @_;

    $class->get_language();
    my %gettext
        = exists $params->{gettext}
        ? %{ $params->{gettext} }
        : ();

    return
        exists $params->{context}
        ? (
            exists $params->{count}
            ? __npx(
                $params->{context},
                $params->{text},
                $params->{plural},
                $params->{count},
                %gettext,
            )
            : __px(
                $params->{context},
                $params->{text},
                %gettext,
            )
        )
        : (
            exists $params->{count}
            ? __nx(
                $params->{text},
                $params->{plural},
                $params->{count},
                %gettext,
            )
            : __x(
                $params->{text},
                %gettext,
            )
        );
}

1;

__END__

$Id$
