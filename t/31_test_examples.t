#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 3);

my @data = (
    {
        test   => 'using default translator',
        path   => 'example',
        script => 'using_default_translator.pl',
        result => <<'EOT',
text=foo &amp; bar
EOT
    },
    {
        test   => 'Locale-Maketext',
        path   => 'example/Locale-Maketext',
        script => 'example.pl',
        result => <<'EOT',
Steffen is programming Perl.
This is the <a href=http://www.perl.org/>link</a>.

Steffen programmiert Perl.
Das ist der <a href=http://www.perl.org/>Link</a>.

EOT
    },
    {
        test   => 'Locale-TextDomain',
        path   => 'example/Locale-TextDomain',
        script => 'example.pl',
        result => <<'EOT',
* placeholder
  Steffen is programming Perl.
* different placeholder escape
  This is the <a href=http://www.perl.org/>link</a>.
* no context
  No context.
* context
  Has context.
* plural
  shelf
  shelves
* context and plural
  good shelf
  good shelves

* placeholder
  Steffen programmiert Perl.
* different placeholder escape
  Das ist der <a href=http://www.perl.org/>Link</a>.
* no context
  Kein Kontext.
* context
  Hat Kontext.
* plural
  Regal
  Regale
* context and plural
  gutes Regal
  gute Regale

EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}