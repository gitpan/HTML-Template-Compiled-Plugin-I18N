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

HTML::Template::Compiled::Plugin::I18N->init(allow_maketext => 1);

my @data = (
    {
        test     => 'maketext, escape HTML for the placeholder',
        template => '<%TEXT VALUE="text<1>" _1="<>"%>',
        result   => 'text=text&lt;1&gt;;maketext=&lt;&gt;',
    },
    {
        test     => 'maketext, escape 0 for the placeholder',
        template => '<%TEXT VALUE="text<2>" _1="<>" _1_ESCAPE=0%>',
        result   => 'text=text&lt;2&gt;;maketext=<>',
    },
    {
        test     => 'maketext, escape URI but not for the placeholder',
        template => '<%TEXT VALUE="text<2>" _1="<>" _1_ESCAPE="HTML" ESCAPE=URI%>',
        result   => 'text=text%3C2%3E;maketext=&lt;&gt;',
    },
    {
        test     => 'maketext, escape URI for the placeholder var too',
        template => '<%TEXT VALUE="text<3>" _1_VAR="value1" ESCAPE="URI"%>',
        params   => {value1 =>'<>'},
        result   => 'text=text%3C3%3E;maketext=%3C%3E',
    },
    {
        test     => 'maketext, escape URI but for the Placeholder HTML|DUMP',
        template => '<%TEXT VALUE="text<4>" _1_VAR="value1" _1_ESCAPE="HTML|DUMP" ESCAPE=URI%>',
        params   => {value1 =>'<>'},
        result   => "text=text%3C4%3E;maketext=\$VAR1 = '&lt;&gt;';\n",
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