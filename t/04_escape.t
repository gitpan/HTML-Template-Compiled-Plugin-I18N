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
        test     => 'no escape',
        template => '<%TEXT "<>"%>',
        result   => 'text=<>',
    },
    {
        test     => 'escape 0',
        template => '<%TEXT "<>" ESCAPE=0%>',
        result   => 'text=<>',
    },
    {
        test     => 'escape HTML',
        template => '<%TEXT "<>" ESCAPE=HTML%>',
        result   => 'text=&lt;&gt;',
    },
    {
        test     => 'escape DUMP',
        template => '<%TEXT "mytext" ESCAPE=DUMP%>',
        result   => "text=\$VAR1 = \\'mytext\\';\n",
    },
    {
        test     => 'escape DUMP|HTML',
        template => '<%TEXT "mytext" ESCAPE=DUMP|HTML%>',
        result   => "text=\$VAR1 = &#39;mytext&#39;;\n",
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