#!perl -T

use strict;
use warnings;

use Test::More tests => 8 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(allow_maketext => 1);

my @data = (
    {
        test     => 'maketext 1 placeholder as text',
        template => '<%TEXT "text1" _1="mt1"%>',
        result   => 'text=text1;maketext=mt1',
    },
    {
        test     => 'maketext 2 placeholders as text',
        template => '<%TEXT "text2" _1="mt1" _2="mt2"%>',
        result   => 'text=text2;maketext=mt1,mt2',
    },
    {
        test     => 'maketext 1 placeholder as var',
        template => '<%TEXT "text3" _1_VAR="value"%>',
        params   => {
            value => 'mt1',
        },
        result   => 'text=text3;maketext=mt1',
    },
    {
        test     => 'maketext 2 placeholders as var',
        template => '<%TEXT "text4" _1_VAR="hash.value1" _2_VAR="hash.value2"%>',
        params   => {
            hash => {value1 => 'mt1', value2 => 'mt2'},
        },
        result   => 'text=text4;maketext=mt1,mt2',
    },
    {
        test     => 'maketext mixed placeholders',
        template => '<%TEXT "text5" _1="mt1" _2_VAR="hash.value2"%>',
        params   => {
            hash => {value2 => 'mt2'},
        },
        result   => 'text=text5;maketext=mt1,mt2',
    },
    {
        test     => 'maketext missing data of placeholders',
        template => '<%TEXT "text6" _1_VAR="var" _2_VAR="hash.value"%>',
        result   => 'text=text6;maketext=undef,undef',
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

