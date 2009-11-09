#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;
BEGIN {
    eval 'use HTML::Entities';
    plan skip_all => "HTML::Entities required for testing ESCAPE=HTML; $EVAL_ERROR" if $EVAL_ERROR;
    eval 'use URI::Escape';
    plan skip_all => "URI::Escape required for testing ESCAPE=URI; $EVAL_ERROR" if $EVAL_ERROR;
    plan tests => 6 + 1;
}
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
        template => '<%TEXT VALUE="text<1>" _1="<>" _1_ESCAPE="HtMl"%>',
        result   => 'text=text<1>;maketext=&lt;&gt;',
    },
    {
        test     => 'maketext, escape HTML but not for the placeholder',
        template => '<%TEXT VALUE="text<2>" _1="<>" _1_ESCAPE="0" ESCAPE=HtMl%>',
        result   => 'text=text&lt;2&gt;;maketext=<>',
    },
    {
        test     => 'maketext, escape URI for the placeholder var',
        template => '<%TEXT VALUE="text<3>" _1_VAR="value1" _1_ESCAPE="UrI"%>',
        params   => {value1 =>'<>'},
        result   => 'text=text<3>;maketext=%3C%3E',
    },
    {
        test     => 'maketext, escape URI but not for the placeholder var',
        template => '<%TEXT VALUE="text<4>" _1_VAR="value1" _1_ESCAPE="0" ESCAPE=UrI%>',
        params   => {value1 =>'<>'},
        result   => 'text=text%3C4%3E;maketext=<>',
    },
#    {
#        test      => 'maketext, unknown escape',
#        template  => '<%TEXT VALUE="text5" _1="<>" _1_ESCAPE="XxX"%>',
#        exception => qr{\@unknown escape XXX}xms,
#    },
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
