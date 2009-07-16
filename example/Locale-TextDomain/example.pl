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
    allow_gettext    => 1,
    translator_class => 'Example::Translator',
);

my $htc = HTML::Template::Compiled->new(
    plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle  => [qw(-classic -comment +asp)],
    scalarref => \<<'EOT');
* placeholder
  <%TEXT NAME="{name} is programming {language}." _name="Steffen" _language_VAR="language"%>
* different placeholder escape
  <%TEXT NAME="This is the {link_begin}link{link_end}." _link_begin="<a href=http://www.perl.org/>" _link_begin_ESCAPE="0" _link_end="</a>" _link_end_ESCAPE="0" ESCAPE="HTML"%>
* no context
  <%TEXT NAME="Context?"%>
* context
  <%TEXT NAME="Context?" CONTEXT="this_context"%>
* plural
  <%TEXT NAME="shelf" PLURAL="shelves" COUNT="1"%>
  <%TEXT NAME="shelf" PLURAL="shelves" COUNT="2"%>
* context and plural
  <%TEXT NAME="shelf" PLURAL="shelves" COUNT="1" CONTEXT="better"%>
  <%TEXT NAME="shelf" PLURAL="shelves" COUNT="2" CONTEXT="better"%>

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

* placeholder
  Steffen is programming Perl.
* different placeholder escape
  This is the <a href=http://www.perl.org/>link</a>.
* no context
  No context.
* context
  Has context.
* plural
  shelf
  shelves
* context and plural
  good shelf
  good shelves

* placeholder
  Steffen programmiert Perl.
* different placeholder escape
  Das ist der <a href=http://www.perl.org/>Link</a>.
* no context
  Kein Kontext.
* context
  Hat Kontext.
* plural
  Regal
  Regale
* context and plural
  gutes Regal
  gute Regale

