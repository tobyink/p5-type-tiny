use strict;
use warnings;
use Test::More;
use Test::TypeTiny;
use Test::Requires 'Specio::Library::Builtins';

BEGIN {
	package Local::MyTypes;
	use Type::Library -base;
	use Type::Utils;
	Type::Utils::extends 'Specio::Library::Builtins';
	$INC{'Local/MyTypes.pm'} = __FILE__;  # allow `use` to work
};

use Local::MyTypes qw(Int ArrayRef);

should_pass 1, Int;
should_pass [], ArrayRef;
should_fail 1, ArrayRef;
should_fail [], Int;

done_testing;
