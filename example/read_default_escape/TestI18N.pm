package TestI18N;

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use HTML::Template::Compiled::Token;

HTML::Template::Compiled->register(__PACKAGE__);

sub register {
    my ($class) = @_;

    return {
        # opening and closing tags to bind to
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                TEXT => [
                    undef,
                    qw(
                        NAME
                        VALUE
                        ESCAPE
                    ),
                ],
            },
        },
        compile => {
            # methods to compile to
            TEXT => {
                # on opening tab
                open => \&TEXT,
            },
        },
    };
}

sub TEXT {
    my ($htc, $token, $arg_ref) = @_;

    () = print {*STDERR} '---', $htc->get_default_escape(), '---';

    return <<"EO_CODE";
$arg_ref->{out} 'mytext';
EO_CODE
}

1;

__END__

$Id$
