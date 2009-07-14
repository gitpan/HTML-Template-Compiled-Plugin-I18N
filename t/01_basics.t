#!perl -T

use strict;
use warnings;

use Test::More tests => 10 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init();

my @data = (
    {
        test     => 'text',
        template => '<%TEXT "text1"%>',
        result   => 'text=text1',
    },
    {
        test     => 'text at attribute NAME',
        template => '<%TEXT NAME="text2"%>',
        result   => 'text=text2',
    },
    {
        test     => 'text in variable',
        template => '<%TEXT VALUE="var"%>',
        params   => {var => 'text3'},
        result   => 'text=text3',
    },
#    {
#        test      => 'text in variable',
#        template  => '<%TEXT NAME="name" VALUE="var"%>',
#        exception => qr{\Qcan't use NAME and VALUE at the same time}xms,
#    },
    {
        test     => 'hash chain',
        template => '<%TEXT VALUE="hash.first_key.second_key"%>',
        params   => {hash => {first_key => {second_key => 'hash1'}}},
        result   => 'text=hash1',
    },
    {
        test     => 'no object',
        template => '<%TEXT VALUE="no_object.get_value"%>',
        params   => {no_object => undef},
        result   => 'text=undef',
    },
    {
        test     => 'object',
        template => '<%TEXT VALUE="object.get_value"%>',
        params   => { object => bless {value => 'object1'}, __PACKAGE__ },
        result   => 'text=object1',
    },
    {
        test     => 'object chain',
        template => '<%TEXT VALUE="outer_object.get_inner_object.get_value"%>',
        params   => {
            do {
                my $inner_object = bless {value => 'object2'}, __PACKAGE__;
                my $outer_object = bless {inner_object => $inner_object}, __PACKAGE__;
                (
                    inner_object => $inner_object,
                    outer_object => $outer_object,
                );
            },
        },
        result   => 'text=object2',
    },
    {
        test      => 'broken object chain',
        template  => '<%TEXT VALUE="outer_object.get_break.get_value"%>',
        params    => {
            do {
                my $inner_object = bless {value => 'object3'}, __PACKAGE__;
                my $outer_object = bless {inner_object => $inner_object}, __PACKAGE__;
                (
                    inner_object => $inner_object,
                    outer_object => $outer_object,
                );
            },
        },
        exception => qr{\QCan't locate object method "get_break"}xms,
    },
#    {
#        test      => 'no maketext',
#        template  => '<%TEXT "no maketext" _1="?"%>',
#        exception => qr{\QSyntax error in <TMPL_*>}xms,
#    },
#    {
#        test      => 'no gettext',
#        template  => '<%TEXT "no gettext" _x="?"%>',
#        exception => qr{\QSyntax error in <TMPL_*>}xms,
#    },
#    {
#        test      => 'no formatter',
#        template  => '<%TEXT "no maketext" ESCAPE=formatter1%>',
#        exception => qr{\QSyntax error in <TMPL_*>}xms,
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

# some methods
# method get_break should missing
sub get_no_object    {return}
sub get_inner_object {return shift->{inner_object}}
sub get_value        {return shift->{value}}
