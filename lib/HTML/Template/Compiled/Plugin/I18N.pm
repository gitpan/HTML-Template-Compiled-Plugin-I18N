package HTML::Template::Compiled::Plugin::I18N;

use strict;
use warnings;

our $VERSION = '0.01_01';

use Carp qw(croak);
use English qw(-no_match_vars $EVAL_ERROR);
use Hash::Util qw(lock_keys);
use Data::Dumper;
use HTML::Template::Compiled;
use HTML::Template::Compiled::Token;
use HTML::Template::Compiled::Plugin::I18N::DefaultTranslator;

our (%init, %escape_sub_of); ## no critic (PackageVars)

BEGIN {
    lock_keys(
        %init,
        qw(
            throw
            allow_maketext
            allow_gettext
            allow_formatter
            translator_class
            escape_plugins
        ),
    );
}

sub _require_via_string {
    my $class = shift;

    eval "require $class" ## no critic (stringy eval)
        or _throw("Can't find package $class $EVAL_ERROR");

    return $class;
}

sub init {
    my ($class, %params) = @_;

    %escape_sub_of = (
        HTML     => \&HTML::Template::Compiled::Utils::escape_html,
        HTML_ALL => \&HTML::Template::Compiled::Utils::escape_html_all,
        URI      => \&HTML::Template::Compiled::Utils::escape_uri,
        JS       => \&HTML::Template::Compiled::Utils::escape_js,
        DUMP     => \&Dumper,
    );

    # get the escape subs for each plugin
    my $escape_plugins = delete $params{escape_plugins};
    if ($escape_plugins) {
        ref $escape_plugins eq 'ARRAY'
           or croak 'Parameter escape_plugins is not an array reference';
        for my $package ( @{$escape_plugins} ) {
            my %escape = %{ _require_via_string($package)->register()->{escape} };
            SUB:
            for my $sub ( values %escape ) {
                # code ref given
                ref $sub eq 'CODE'
                    and next SUB;
                # sub name given
                no strict qw(refs); ## no critic (NoStrict)
                no warnings qw(redefine); ## no critic (NoWarnings)
                $sub = \&{$sub};
            }
            @escape_sub_of{ keys %escape } = values %escape;
        }
    }

    # and all the other boolenans and strings
    my @keys = keys %params;
    @init{@keys} = @params{@keys};
    $init{translator_class} ||= 'HTML::Template::Compiled::Plugin::I18N::DefaultTranslator';
    _require_via_string($init{translator_class});

    HTML::Template::Compiled->register(__PACKAGE__);

    return $class;
}

sub _throw {
    my @message = @_;

    return
        ref $init{throw} eq 'CODE'
        ? $init{throw}->(@message)
        : croak @message;
}

sub register {
    my ($class) = @_;

    return {
        # opening and closing tags to bind to
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                TEXT => [
                    undef,
                    # attributes
                    qw(
                        NAME
                        VALUE
                        ESCAPE
                    ),
                    (
                        $init{allow_maketext}
                        ? qw(
                            _\d+
                            _\d+_VAR
                            _\d+_ESCAPE
                        )
                        : ()
                    ),
                    (
                        $init{allow_gettext}
                        ? qw(
                            PLURAL
                            PLURAL_VAR
                            QUANTITY
                            QUANTITY_VAR
                            CONTEXT
                            CONTEXT_VAR
                            _[A-Z][0-9A-Z_]*?
                            _[A-Z][0-9A-Z_]*?_VAR
                            _[A-Z][0-9A-Z_]*?_ESCAPE
                        )
                        : ()
                    ),
                    (
                        $init{allow_formatter}
                        ? qw(
                            FORMATTER
                        )
                        : ()
                    ),
                ],
            },
        },
        compile => {
            # methods to compile to
            TEXT => {
                # on opening tab
                open => \&TEXT,
                # if you need closing, uncomment and implement method
                # close => \&close_text
            },
        },
    };
}

sub _lookup_variable {
    my ($htc, $var_name) = @_;

    return $htc->get_compiler()->parse_var(
        $htc,
        var            => $var_name,
        method_call    => $htc->method_call(),
        deref          => $htc->deref(),
        formatter_path => $htc->formatter_path(),
    );
}

sub _calculate_escape {
    my $params = shift;

    my @real_escapes;
    ESCAPE:
    for my $escape ( @{ $params->{escapes} } ) {
        if ($escape eq '0') {
            @real_escapes = ();
            next ESCAPE;
        }
        push @real_escapes, $escape;
    }
    # check errors
    my @unknown_escapes;
    ESCAPE:
    for my $escape (@real_escapes) {
        exists $escape_sub_of{$escape}
            and next ESCAPE;
        push @unknown_escapes, $escape;
    }
    # write back
    if ( exists $params->{escape_ref} ) {
        ${ $params->{escape_ref} } = \@real_escapes;
    }

    return @unknown_escapes ? \@unknown_escapes : ();
}

sub _escape {
    my ($string, $escape_ref) = @_;

    $escape_ref
        or return $string;
    for ( @{$escape_ref} ) {
        $string = $escape_sub_of{$_}->($string);
    }

    return $string;
}

sub escape {
    my ($string, @escapes) = @_;

    return _escape($string, \@escapes);
}

sub _escape_and_set_quotes {
    my $string = shift;

    defined $string
        or return q{''};
    $string =~ s{\\}{\\}xmsg;
    $string =~ s{'}{\\'}xmsg;
    $string =~ s{"}{\\"}xmsg;

    return "'$string'";
}

sub TEXT { ## no critic (ExcessComplexity)
    my ($htc, $token, $arg_ref) = @_;

    my $attr_ref = $token->get_attributes();
    my $filename = $htc->get_filename();

    # ATTENTION: $attr->{NAME} and $attr->{VAR} isn't mandatory
    # but we we have to pass q{} instead of undef
    # resolve var if existant (eg. <%TEXT a_var_dingens ...

    my %data = (
        filename => {
            value => $filename,
        },
    );
    ATTRIBUTE:
    for my $name ( keys %{$attr_ref} ) {
        # ESCAPE
        if ($name eq 'ESCAPE') {
            if ( length $attr_ref->{$name} ) {
                $data{escape}->{array}
                    = [ split m{\|}xms, "0|$attr_ref->{$name}" ];
            }
        }
        if ( $init{allow_maketext} ) {
            my $is_maketext
                = my ($position, $is_variable, $is_escape)
                = $name =~ m{
                    \A _ (\d+) (?:
                        (_VAR)
                        | (_ESCAPE)
                    )? \z}xms;
            if ($is_maketext) {
                my $index = $position - 1;
                my $data_of_index = $data{maketext}->{array}->[$index] ||= {};
                # _n_ESCAPE
                if ($is_escape) {
                    if ( exists $data_of_index->{escape} ) {
                        _throw("error in template $filename can't use maktext escape position $position twice");
                    }
                    $data_of_index->{escape}->{array}
                        = length $attr_ref->{$name}
                        ? [ split m{\|}xms, "0|$attr_ref->{$name}" ]
                        : ();
                }
                # _n, _n_VAR
                else {
                    if ( exists $data_of_index->{data} ) {
                        _throw("error in template $filename can't use maktext position $position twice");
                    }
                    $data_of_index->{data} = {
                        is_variable => $is_variable,
                        value       => $attr_ref->{$name},
                    };
                }
                next ATTRIBUTE;
            }
        }
        if ( $init{allow_gettext} ) {
            my $is_gettext
                = my ($key, $is_variable, $is_escape)
                = $name =~ m{
                    \A _ ([A-Z][0-9A-Z_]*?) (?:
                        (_VAR)
                        | (_ESCAPE)
                    )? \z}xms;
            if ($is_gettext) {
                my $data_of_key = $data{gettext}->{hash}->{lc $key} ||= {};
                # _name_ESCAPE
                if ($is_escape) {
                    if ( exists $data_of_key->{escape} ) {
                        _throw("error in template $filename can't use gettext escape $key twice");
                    }
                    $data_of_key->{escape}->{array}
                        = length $attr_ref->{$name}
                        ? [ split m{\|}xms, "0|$attr_ref->{$name}" ]
                        : ();
                }
                # _name, _name_VAR
                else {
                    if ( exists $data_of_key->{data} ) {
                        _throw("error in template $filename can't use gettext key $key twice");
                    }
                    $data_of_key->{data} = {
                        is_variable => $is_variable,
                        value       => $attr_ref->{$name},
                    };
                }
                next ATTRIBUTE;
            }
            # PLURAL
            my $is_plural
                = ($is_variable)
                = $name =~ m{\A PLURAL (_VAR)? \z}xms;
            if ($is_plural) {
                if ( exists $data{plural} ) {
                    _throw("error in template $filename can't use PLURAL/PLURAL_VAR twice");
                }
                $data{plural} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
            # QUANTITY, QUANTITY_VAR
            my $is_quantity
                = ($is_variable)
                = $name =~ m{\A QUANTITY (_VAR)? \z}xms;
            if ($is_quantity) {
                if ( exists $data{quantity} ) {
                    _throw("error in template $filename can't use QUANTITY/QUANTITY_VAR twice");
                }
                $data{quantity} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
            # CONTEXT
            my $is_context
                = ($is_variable)
                = $name =~ m{\A CONTEXT (_VAR)? \z}xms;
            if ($is_context) {
                if ( exists $data{context} ) {
                    _throw("error in template $filename can't use CONTEXT/CONTEXT_VAR twice");
                }
                $data{context} = {
                    is_variable => $is_variable,
                    value       => $attr_ref->{$name},
                };
                next ATTRIBUTE;
            }
        }
        if ( $init{allow_formatter} ) {
            # FORMATTER
            if ( $name eq 'FORMATTER' ) {
                if ( exists $data{formatter} ) {
                    _throw("error in template $filename can't use FORMATTER twice");
                }
                $data{formatter}->{array} = [
                    map {
                        {value => $_};
                    } split m{\|}xms, $attr_ref->{$name}
                ];
                next ATTRIBUTE;
            }
        }
    }

    if ( $init{allow_maketext} && exists $data{maketext} ) {
        my $data_maketext = $data{maketext}->{array};
        INDEX:
        for my $index ( 0 .. $#{$data_maketext} ) {
            my $data_of_index = $data_maketext->[$index];
            my $unknown_escapes = _calculate_escape({
                escapes => [
                    $htc->get_default_escape(),
                    (
                        exists $data{escape}
                        ? @{ $data{escape}->{array} }
                        : ()
                    ),
                    (
                        exists $data_of_index->{escape}
                        ? @{ $data_of_index->{escape}->{array} }
                        : ()
                    ),
                ],
                escape_ref => \$data_of_index->{escape},
            });
            if ($unknown_escapes) {
                _throw(
                    "error in template $filename, maketext escape $index, unknown escape "
                    . ( join ', ', @{$unknown_escapes} )
                    . ' for HTC Plugin '
                    . __PACKAGE__
                );
            }
        }
    }
    if ( $init{allow_gettext} && exists $data{gettext} ) {
        my $data_gettext = $data{gettext}->{hash};
        KEY:
        for my $key ( keys %{$data_gettext} ) {
            my $data_of_key = $data_gettext->{$key};
            my $unknown_escapes = _calculate_escape({
                escapes => [
                    $htc->get_default_escape(),
                    (
                        exists $data{escape}
                        ? @{ $data{escape}->{array} }
                        : ()
                    ),
                    (
                        exists $data_of_key->{escape}
                        ? @{ $data_of_key->{escape}->{array} }
                        : ()
                    ),
                ],
                escape_ref => \$data_of_key->{escape},
            });
            if ($unknown_escapes) {
                _throw(
                    "error in template $filename, gettext escape $key, unknown escape "
                    . ( join ', ', @{$unknown_escapes} )
                    . ' for HTC Plugin '
                    . __PACKAGE__
                );
            }
        }
    }

    # NAME/VALUE
    $data{text} = {
        exists $attr_ref->{NAME}
        ? (
            exists $attr_ref->{VALUE}
            ? _throw(
                "error in template $filename: "
                . q{you can't use NAME and VALUE at the same time for HTC Plugin }
                . __PACKAGE__ . Data::Dumper::Dumper $attr_ref
            )
            : (
                value => $attr_ref->{NAME},
            )
        )
        : (
            is_variable => 1,
            value       => $attr_ref->{VALUE},
        )
    };

    # ESCAPE
    my $unknown_escapes = _calculate_escape({
        escapes => [
            $htc->get_default_escape(),
            (
                exists $data{escape}
                ? @{ $data{escape}->{array} }
                : ()
            ),
        ],
        escape_ref => \$data{escape}->{array},
    });
    if ($unknown_escapes) {
        _throw(
            "error in template $filename, unknown escape "
            . ( join ', ', @{$unknown_escapes} )
            . ' for HTC Plugin '
            . __PACKAGE__
        );
    }
    if ( exists $data{escape} && ! @{ $data{escape}->{array} } ) {
        delete $data{escape};
    }

    my $escape_sub = sub {
        my ($data, $escape_ref) = @_;

        if ( $data->{is_variable} ) {
            return
                $escape_ref
                ? (
                    __PACKAGE__
                    . '::escape('
                    . _lookup_variable($htc, $data->{value})
                    . q{,}
                    . (
                        join q{,}, map {
                            _escape_and_set_quotes($_);
                        } @{$escape_ref}
                    )
                    . q{)}
                )
                : _lookup_variable($htc, $data->{value});
        }
        defined $data->{value}
            or return 'undef';

        return
            _escape_and_set_quotes(
                $escape_ref
                ? _escape(
                    $data->{value},
                    $escape_ref,
                )
                : $data->{value},
            );
    };
    # run for real escapes
    ESCAPE:
    for my $key ( qw(filename text plural quantity context) ) {
        exists $data{$key}
            or next ESCAPE;
        my $data = $data{$key};
        $data->{escaped} = $escape_sub->(
            $data,
            exists $data{escape}
            ? $data{escape}->{array}
            : (),
        );
    }
    ESCAPE:
    for my $key ( qw(maketext) ) {
        exists $data{$key}
            or next ESCAPE;
        my $data = $data{$key};
        $data->{escaped}
            = q{[}
            . (
                join q{,}, map {
                    $escape_sub->(
                        $_->{data},
                        exists $_->{escape}
                        ? $_->{escape}
                        : (),
                    );
                } @{ $data->{array} }
            )
            . q{]};
    }
    ESCAPE:
    for my $key ( qw(gettext) ) {
        exists $data{$key}
            or next ESCAPE;
        my $data = $data{$key};
        $data->{escaped}
            = q[{]
            . (
                join q{,}, map {
                    _escape_and_set_quotes($_)
                    . ' => '
                    . $escape_sub->(
                        $data->{hash}->{$_}->{data},
                        exists $data->{hash}->{$_}->{escape}
                        ? $data->{hash}->{$_}->{escape}
                        : (),
                    )
                } keys %{ $data->{hash} }
            )
            . q[}];
    }
    ESCAPE:
    for my $key ( qw(formatter) ) {
        exists $data{$key}
            or next ESCAPE;
        my $data = $data{$key};
        $data->{escaped}
            = q{[}
            . (
                join q{,}, map {
                    $escape_sub->($_);
                } @{ $data->{array} }
            )
            . q{]};
    }

    delete $data{escape};

    # necessary for HTC's caching mechanism
    my $inner_hash = join ', ', map {
        ( $_ eq 'filename' || exists $data{$_} )
        ? "$_ => $data{$_}->{escaped}"
        : ();
    } keys %data;

    # be careful in returns - they are double quoted strings.
    # escape variable names, if you mean variables, do not qoute (but put
    # quotes around) variables if you mean their content...
    return <<"EO_CODE";
$arg_ref->{out} $init{translator_class}->translate({$inner_hash});
EO_CODE
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::I18N - Internationalization for HTC

$Id: I18N.pm 59 2009-07-14 09:10:09Z steffenw $

$HeadURL: https://htc-plugin-i18n.svn.sourceforge.net/svnroot/htc-plugin-i18n/trunk/lib/HTML/Template/Compiled/Plugin/I18N.pm $

=head1 VERSION

0.01_01

=head1 SYNOPSIS

=head2 create a translator class

    package MyProjectTranslator;

    sub translate {
        my ($class, $params) = @_;

        return $params->{text};
    }

=head2 initialize plugin and then the template

    use HTML::Template::Compiled;
    use HTML::Template::Compiled::Plugin::I18N;

    HTML::Template::Compiled::Plugin::I18N->init(
        # all parameters are optional
        escape_plugins => [ qw(
            HTML::Template::Compiled::Plugins::ExampleEscape
        ) ],
        translator_class => 'MyProjectTranslator',
    );

    my $htc = HTML::Template::Compiled->new(
        plugin    => [ qw(
            HTML::Template::Compiled::Plugin::I18N
            HTML::Template::Compiled::Plugin::ExampleEscape
        ) ],
        scalarref => \'<%TEXT VALUE="Hello World!" %>',
    );
    print $htc->output();

=head1 DESCRIPTION

The Plugin allows you to create multilingual templates
including maketext and/or gettext features.

Before you have written your own translator class,
HTML::Template::Compiled::I18N::DefaultTranslator runs.

Later you have to write a translator class
to connect the plugin to your selected translation module.

=head1 TEMPLATE SYNTAX

=head2 text only

=over

=item * static text values

    <%TEXT VALUE="some static text"%>
    <%TEXT VALUE="some static text" ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text => 'some staic text',
    }

=item * text from a variable

    <%TEXT a.var%>
    <%TEXT a.var ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text => $a->var(), # or $a->{var}
    }

=back

=head2 formatter

=over

=item * 1 formatter

   <%TEXT VALUE="some **marked** text" FORMATTER="markdown"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text      => 'some **marked** text',
        formatter => [qw( markdown )],
    }

=item * more formatters

   <%TEXT VALUE="some **marked** text" FORMATTER="markdown|second"%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text      => 'some **marked** text',
        formatter => [qw( markdown second)],
    }

=back

=head2 Locale::Maketext placeholders

Allow maketext during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_maketext => $true_value,
        ...
    );

=over

=item with an static value

    <%TEXT VALUE="Hello [_1]!" _1="world"%>
    <%TEXT VALUE="Hello [_1]!" _1="world" _1_ESCAPE=0%>
    <%TEXT VALUE="Hello [_1]!" _1="world" ESCAPE=HTML%>
    <%TEXT VALUE="Hello [_1]!" _1="world" _1_ESCAPE=0 ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text     => 'Hello [_1]!',
        maketext => [ qw( world ) ],
        # escapes were handled already
    }

=item with an variable

    <%TEXT VALUE="Hello [_1]!" _1_VAR="var.with.the.value"%>
    <%TEXT VALUE="Hello [_1]!" _1_VAR="var.with.the.value" _1_ESCAPE=0%>
    <%TEXT VALUE="Hello [_1]!" _1_VAR="var.with.the.value" ESCAPE=HTML%>
    <%TEXT VALUE="Hello [_1]!" _1_VAR="var.with.the.value" _1_ESCAPE=0 ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text     => 'Hello [_1]!',
        maketext => [ $var->with()->the()->value() ],
        # escapes were handled already
    }

=item mixed samples

    <%TEXT VALUE="The [_1] is [_2]." _1="window" _2="blue" %>
    <%TEXT a.text                    _1="window" _2_VAR="var.color" %>

=back

=head2 Locale::TextDomain placeholders

Allow gettext during initialization.

    HTML::Template::Compiled::Plugin::I18N->init(
        allow_gettext => $true_value,
        ...
    );

=over

=item with an static value

    <%TEXT VALUE="Hello {name}!" _name="world"%>
    <%TEXT VALUE="Hello {name}!" _name="world" _name_ESCAPE=0%>
    <%TEXT VALUE="Hello {name}!" _name="world" ESCAPE=HTML%>
    <%TEXT VALUE="Hello {name}!" _name="world" _name_ESCAPE=0 ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text    => 'Hello {name}!',
        gettext => { name => 'world' },
        # escapes were handled already
    }

=item with an variable

    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value"%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value" _name_ESCAPE=0%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value" ESCAPE=HTML%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value" _name_ESCAPE=0 ESCAPE=HTML%>

The 2nd parameter of the method translate (translator class) will set to:

    {
        text    => 'Hello {name}!',
        gettext => { name => $var->with()->the()->value() },
        # escapes were handled already
    }

=item plural forms TODO with PLURAL PLURAL_VAR _name_QUANTITY _name_QUANTITY_VAR

    <%TEXT VALUE="Hello {name}!" _name="world"%>
    <%TEXT VALUE="Hello {name}!" _name="world" _name_ESCAPE=0%>
    <%TEXT VALUE="Hello {name}!" _name="world" ESCAPE=HTML%>
    <%TEXT VALUE="Hello {name}!" _name="world" _name_ESCAPE=0 ESCAPE=HTML%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value"%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value _name_ESCAPE=0"%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value" ESCAPE=HTML%>
    <%TEXT VALUE="Hello {name}!" _name_VAR="var.with.the.value" _name_ESCAPE=0 ESCAPE=HTML%>

=back

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 SUBROUTINES/METHODS

=cut head2 _require_via_string

internal sub to classes late

=head2 init

Call init before the HTML::Template::Compiled object will created.

    # all parameters are optional
    HTML::Template::Compiled::Plugin::I18N->init(
        throw            => sub {
            croak @_; # this is the default
        }
        allow_maketext   => $boolean,
        allow_gettext    => $boolean,
        allow_formatter  => $boolean,
        translator_class => 'TranslatorClassName',
        escape_plugins   => [ qw(
            the same like
            HTML::Template::Compiled->new(plugin => [qw( ...
            but escape plugins only
        )],
    );

=cut head2 _throw

Internally used to throw exceptions.

    _throw(@message);

=head2 register

HTML::Template::Compiled will call this method to register this plugin.

    register($class);

=cut

 =head2 _lookup_variable

Internally used to get the real value.

    _lookup_variable($htc, $var_name);

 =head2 _calculate_escape

Calculate the real escape using the default escape,
the escape for the tag and
the escape for the placeholder.

    $unknown_escapes = _calculate_escape({
        escapes    => [qw( given_escapes )],
        escape_ref => \$how_to_write_bak_the_real_escape_array_ref,
    });

$unknown_escapes is undef or an array_ref.

 =head2 _escape

Internally used to run the escapeing.

    $escaped_string = _escape($string, $escape_array_ref);

=head2 escape

Called from compiled code only.

    $escaped_string
        = HTML::Template::Compiled::Plugin::I18N::escape($string, @escapes);

=cut

 =head2 _escape_and_set_quotes

Internally used to build values as code snippets.

    $quoted_string = _escape_and_set_quotes($string);

=head2 TEXT

Do not call this method.
It is used to create the HTC Template Code.
This method is used as callback which is registerd to HTML::Template::Compiled
by our register method.

It calls the translate method of the Translator class 'TranslatorClassNames'.

The translate method will called like

    $translator = TranslatorClass->new()->translate({
        text => 'result of variable lookup or VALUE',
        ...
    });

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

Call init method beform C<HTML::Template::Compiled->new(...)>.

=head1 DEPENDENCIES

Carp

English

L<Hash::Util>

L<Data::Dumper>

L<HTML::Template::Compiled>

L<HTML::Template::Compiled::Token>

L<HTML::Template::Compiled::I18N::DefaultTranslator>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<HTML::Template::Compiled>

L<Hyper::Template::Plugin::Text>
This is the idea for this module.
This can not support escape.
This can not handle gettext.
The module is too Hyper-ish and not for common use.

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
