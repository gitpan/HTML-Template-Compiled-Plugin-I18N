package Example::I18N;

use strict;
use warnings;

our $VERSION = 0;

use parent qw(Locale::Maketext); # inheritance
use Locale::Maketext::Lexicon;

Locale::Maketext::Lexicon->import({
    q{*}    => [Gettext => './locale/*/LC_MESSAGES/example.po'],
    # use unicode
    _decode => 1,
    # %1, %2 written as placeholders at po file.
    #_style  => 'gettext',
    # fallback at missing keys
    #_auto   => 1,
});

1;

__END__

$Id$

