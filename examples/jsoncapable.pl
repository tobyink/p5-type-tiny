use strict;
use warnings;
use feature 'say';

BEGIN {
	package My::Types;
	use Type::Library 1.012
		-utils,
		-extends => [ 'Types::Standard' ],
		-declare => 'JSONCapable';
	
	declare JSONCapable,
		as Undef
		|  ScalarRef[ Enum[ 0..1 ] ]
		|  Num
		|  Str
		|  ArrayRef[ JSONCapable ]
		|  HashRef[ JSONCapable ]
		;
}

use My::Types 'is_JSONCapable';

my $var = {
	foo => 1,
	bar => [ \0, "baz", [] ],
};

say is_JSONCapable $var;
