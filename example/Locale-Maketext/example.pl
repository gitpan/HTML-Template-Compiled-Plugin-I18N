#!perl

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR);
use HTML::Template::Compiled;
use HTML::Template::Compiled::Plugin::I18N;
use lib qw(./lib);
use Example::Translator;

HTML::Template::Compiled::Plugin::I18N->init(
    allow_maketext   => 1,
    translator_class => 'Example::Translator',
);

my $htc = HTML::Template::Compiled->new(
    plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle  => [qw(-classic -comment +asp)],
    scalarref => \<<'EOT');
<%TEXT VALUE="[_1] is programming [_2]." _1="Steffen" _2_VAR="language"%>
<%TEXT VALUE="This is the [_1]link[_2]." _1="<a href=http://www.perl.org/>" _1_ESCAPE="0" _2="</a>" _2_ESCAPE="0" ESCAPE="HTML"%>

EOT
$htc->param(
    language => 'Perl',
);

binmode STDOUT, 'encoding(utf-8)'
    or croak "Can not switch encoding for STDOUT to utf-8: $OS_ERROR";
Example::Translator->set_language('en_GB');
() = print $htc->output();

Example::Translator->set_language('de_DE');
() = print $htc->output();

# $Id$

__END__

Output:

Steffen is programming Perl.
This is the <a href=http://www.perl.org/>link</a>.

Steffen programmiert Perl.
Das ist der <a href=http://www.perl.org/>Link</a>.