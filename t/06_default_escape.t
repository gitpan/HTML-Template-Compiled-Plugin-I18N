#!perl -T

use strict;
use warnings;

use Test::More tests => 7 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init();

my @data = (
    {
        test     => 'default escape HTML',
        template => '<%TEXT VALUE="text<1>"%>',
        result   => 'text=text&lt;1&gt;',
    },
    {
        test     => 'escape 0',
        template => '<%TEXT VALUE="text<2>" ESCAPE=0%>',
        result   => 'text=text<2>',
    },
    {
        test     => 'escape URI',
        template => '<%TEXT VALUE="text<3>" ESCAPE=URI%>',
        result   => 'text=text%3C3%3E',
    },
    {
        test     => 'escape DUMP',
        template => '<%TEXT VALUE="text<4>" ESCAPE=DUMP%>',
        result   => "text=\$VAR1 = \\'text<4>\\';\n",
    },
    {
        test     => 'escape DUMP|HTML',
        template => '<%TEXT VALUE="text<5>" ESCAPE=DUMP|HTML%>',
        result   => "text=\$VAR1 = &#39;text&lt;5&gt;&#39;;\n",
    },
);

for my $data (@data) {
    my $htc = HTML::Template::Compiled->new(
        tagstyle       => [qw(-classic -comment +asp)],
        plugin         => [qw(HTML::Template::Compiled::Plugin::I18N)],
        default_escape => 'HTML',
        scalarref      => \$data->{template},
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