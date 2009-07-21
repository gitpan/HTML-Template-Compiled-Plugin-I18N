package HTML::Template::Compiled::Plugin::I18N::DefaultTranslator;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01_04';

my $escape_ref = sub {
    my $string = shift;

    defined $string
        and return $string;

    return 'undef';
};

sub set_escape {
    my (undef, $code_ref) = @_;

    ref $code_ref eq 'CODE'
        or croak 'Coderef expected';
    $escape_ref = $code_ref;

    return;
}

sub get_escape {
    return $escape_ref;
}

sub translate {
    my (undef, $attr_ref) = @_;

    return join q{;}, map {
        exists $attr_ref->{$_}
        ? (
            "$_="
            . join q{,}, map {
                $escape_ref->($_);
            } (
                ref $attr_ref->{$_} eq 'ARRAY'
                ? @{ $attr_ref->{$_} }
                : ref $attr_ref->{$_} eq 'HASH'
                ? do {
                    my $key = $_;
                    map {
                        ( $_, $attr_ref->{$key}->{$_} );
                    } sort keys %{ $attr_ref->{$key} };
                }
                : $attr_ref->{$_}
            )
        )
        : ();
    } qw(
        context text plural maketext count gettext formatter
    );
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::I18N::DefaultTranslator
- an extremly simple translater class for the HTC plugin I18N

$Id: DefaultTranslator.pm 109 2009-07-21 05:11:15Z steffenw $

$HeadURL: https://htc-plugin-i18n.svn.sourceforge.net/svnroot/htc-plugin-i18n/trunk/lib/HTML/Template/Compiled/Plugin/I18N/DefaultTranslator.pm $

=head1 VERSION

0.01_04

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is very useful to run the application
before the translator module has finished.

The output string is human readable.

=head1 SUBROUTINES/METHODS

=head2 class method set_escape

Set a escape code reference to escape all the values.
The example describes the default to have no undefined values.

    HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->set_escape(
        sub {
            my $string = shift;

            defined $string
                and return $string;

            return 'undef';
        },
    );

=head2 class method get_escape

Get back the current escape code reference.

   $code_ref
       = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->get_escape();

=head2 class method translate

Possible hash keys are
context, text, plural, maketext, count, gettext and formatter.

    $string
        = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->translate({
            text => 'text',
            ...
        });

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

Carp

=head1 INCOMPATIBILITIES

The output is not readable by a parser
but very good during the application development.

=head1 BUGS AND LIMITATIONS

not known

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