package HTML::Template::Compiled::Plugin::I18N::TestTranslator;

use strict;
use warnings;

use Carp qw(croak);
# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);

my %lexicon = (
    de => {
        'Hello world!' => 'Hallo Welt!',
    },
);

sub new {
    my ($class, @more) = @_;

    return $class->instance(@more);
}

sub set_language {
    my ($self, $language) = @_;

    $self->{language} = $language;

    return $self;
}

sub get_language {
    my $self = shift;

    my $language = $self->{language}
        or croak 'No language set';

    return $language;
}

sub translate {
    my ($class, $params) = @_;

    my $self = $class->new();

    SEARCH: {
        my $language = $self->get_language();
        exists $lexicon{$language}
            or last SEARCH;
        my $lexicon_of_language = $lexicon{$language};
        exists $lexicon_of_language->{ $params->{text} }
            and return $lexicon_of_language->{ $params->{text} };
    }

    return $params->{text};
}

1;