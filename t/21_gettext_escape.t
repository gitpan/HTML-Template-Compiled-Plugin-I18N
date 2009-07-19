#!perl -T

use strict;
use warnings;

use Test::More tests => 6 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(allow_gettext => 1);

my @data = (
    {
        test     => 'gettext, escape HTML for the placeholder',
        template => '<%TEXT VALUE="text<1>" _name="<>" _name_ESCAPE="HTML"%>',
        result   => 'text=text<1>;gettext=name,&lt;&gt;',
    },
    {
        test     => 'gettext, escape HTML but not for the placeholder',
        template => '<%TEXT VALUE="text<2>" _name="<>" _name_ESCAPE="0" ESCAPE=HTML%>',
        result   => 'text=text&lt;2&gt;;gettext=name,<>',
    },
    {
        test     => 'gettext, escape URI for the placeholder var',
        template => '<%TEXT VALUE="text<3>" _name_VAR="value1" _name_ESCAPE="URI"%>',
        params   => {value1 =>'<>'},
        result   => 'text=text<3>;gettext=name,%3C%3E',
    },
    {
        test     => 'gettext, escape URI but not for the placeholder var',
        template => '<%TEXT VALUE="text<4>" _name_VAR="value1" _name_ESCAPE="0" ESCAPE=URI%>',
        params   => {value1 =>'<>'},
        result   => 'text=text%3C4%3E;gettext=name,<>',
    },
);

for my $data (@data) {
    my $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
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