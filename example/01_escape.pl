#!perl

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use HTML::Template::Compiled::Plugin::I18N;

HTML::Template::Compiled::Plugin::I18N->init();

my $htc = HTML::Template::Compiled->new(
    plugin         => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle       => [qw(-classic -comment +asp)],
    scalarref      => \<<'EOT');
<%TEXT NAME="bla bla"%>
EOT
$htc->param(
);
() = print $htc->output();

# $Id$

__END__

Output:

bla bla
