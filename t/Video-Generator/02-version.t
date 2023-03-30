use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Video::Generator;

# Test.
is($Video::Generator::VERSION, 0.11, 'Version.');
