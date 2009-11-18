package HTML::Template::Compiled::Plugin::I18N::TestTranslator;

use strict;
use warnings;

use Carp qw(croak);
use HTML::Template::Compiled::Plugin::I18N;
# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);

my %lexicon = (
    de => {
        'Hello <world>!' => 'Hallo <Welt>!',
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
    my ($class, $arg_ref) = @_;

    my $self = $class->new();

    SEARCH: {
        my $language = $self->get_language();
        exists $lexicon{$language}
            or last SEARCH;
        my $lexicon_of_language = $lexicon{$language};
        $arg_ref->{text}
            or last SEARCH;
        exists $lexicon_of_language->{ $arg_ref->{text} }
            or last SEARCH;
        my $translation = $lexicon_of_language->{ $arg_ref->{text} }
            or return 'undef';
        if ( exists $arg_ref->{escape} ) {
            $translation = HTML::Template::Compiled::Plugin::I18N->escape(
                $translation,
                $arg_ref->{escape},
            );
        }

        return $translation;
    }

    return $arg_ref->{text};
}

1;