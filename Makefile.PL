# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Perl class for video generation.';
author 'Michal Spacek <skim@cpan.org>';
license 'bsd';
name 'Video-Generator';
readme_from 'Generator.pm';
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.17;
requires 'File::Path' => 0;
requires 'File::Spec::Functions' => 0;
requires 'File::Temp' => 0;
requires 'IO::CaptureOutput' => 0;
requires 'Image::Random' => 0;
requires 'Video::Delay::Const' => 0;
requires 'Video::Pattern' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Video-Generator';
resources 'homepage' => 'https://github.com/tupinek/Video-Generator';
resources 'repository' => 'git://github.com/tupinek/Video-Generator';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
