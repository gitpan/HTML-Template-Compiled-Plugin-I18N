package HTML::Template::Compiled::Plugin::I18N::DefaultTranslator;

use strict;
use warnings;

our $VERSION = '0.01';

my $escape = sub {
    my $string = shift;

    defined $string
        or return q{undef};
    $string =~ s{\\}{\\}xmsg;
    $string =~ s{'}{\\'}xmsg;
    $string =~ s{"}{\\"}xmsg;

    return $string;
};

sub translate {
    my (undef, $params) = @_;

    return join q{;}, map {
        exists $params->{$_}
        ? (
            "$_="
            . join q{,}, map {
                $escape->($_);
            } (
                ref $params->{$_} eq 'ARRAY'
                ? @{ $params->{$_} }
                : ref $params->{$_} eq 'HASH'
                ? do {
                    my $key = $_;
                    map {
                        ( $_, $params->{$key}->{$_} );
                    } sort keys %{ $params->{$key} };
                }
                : $params->{$_}
            )
        )
        : ();
    } qw(
        context text plural maketext quantity gettext formatter
    );
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::I18N::DefaultTranslator
- an extremly simple translater class for the HTC plugin I18N

$Id: DefaultTranslator.pm 49 2009-07-12 20:27:59Z steffenw $

$HeadURL: https://htc-plugin-i18n.svn.sourceforge.net/svnroot/htc-plugin-i18n/trunk/lib/HTML/Template/Compiled/Plugin/I18N/DefaultTranslator.pm $

=head1 VERSION

0.01_01

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is very useful to run the application
before the translator module has finished.

The string output is human readable.
\, ' and " are quoted to have no problems at JavaScript strings.

=head1 SUBROUTINES/METHODS

=head2 method translate

Possible hash keys are
context, text, plural, maketext, quantity, gettext and formatter.

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

none

=head1 INCOMPATIBILITIES

not readable by a parser

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