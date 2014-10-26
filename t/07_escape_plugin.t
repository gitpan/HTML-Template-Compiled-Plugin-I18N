#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(
    escape_plugins => [qw( HTML::Template::Compiled::Plugin::XMLEscape )],
);

my @data = (
    {
        test     => 'escape XML',
        template => '<%TEXT VALUE="<>" ESCAPE=XML%>',
        result   => 'text=&#x3C;&#x3E;',
    },
    {
        test     => 'escape XML_ATTR',
        template => '<%TEXT VALUE="<>" ESCAPE=XML_ATTR%>',
        result   => 'text=&#x3C;&#x3E;',
    },
);

for my $data (@data) {
    my $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        plugin    => [qw(
            HTML::Template::Compiled::Plugin::I18N
            HTML::Template::Compiled::Plugin::XMLEscape
        )],
        scalarref => \$data->{template},
    );
    if ( exists $data->{params} ) {
        $htc->param( %{ $data->{params} } );
    }
    if ( exists $data->{exception} ) {
        throws_ok(
            sub { $htc->output() },
            $data->{exception},
            $data->{test},
        );
    }
    else {
        is(
            $htc->output(),
            $data->{result},
            $data->{test},
        );
    }
}