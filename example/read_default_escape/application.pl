#!perl

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use TestI18N;

my $htc = HTML::Template::Compiled->new(
    tagstyle => [qw(-classic -comment +asp)],
    plugin => [ qw(
        TestI18N
    ) ],
    default_escape => 'HTML',
    scalarref => \'<%TEXT VALUE="Hello World!" %>',
);
$htc->output();

# $Id$
