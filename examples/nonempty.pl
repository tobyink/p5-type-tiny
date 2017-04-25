use v5.14;
use strict;
use warnings;

package Example1 {
	use Moo;
	use Sub::Quote 'quote_sub';
	use Types::Standard -types;
	
	has my_string => (
		is    => 'ro',
		isa   => Str->where( 'length($_) > 0' ),
	);
	
	has my_array => (
		is    => 'ro',
		isa   => ArrayRef->where( '@$_ > 0' ),
	);
	
	has my_hash => (
		is    => 'ro',
		isa   => HashRef->where( 'keys(%$_) > 0' ),
	);
}

use Test::More;
use Test::Fatal;

is(
	exception { Example1::->new( my_string => 'u' ) },
	undef,
	'non-empty string, okay',
);

isa_ok(
	exception { Example1::->new( my_string => '' ) },
	'Error::TypeTiny',
	'result of empty string',
);

is(
	exception { Example1::->new( my_array => [undef] ) },
	undef,
	'non-empty arrayref, okay',
);

isa_ok(
	exception { Example1::->new( my_array => [] ) },
	'Error::TypeTiny',
	'result of empty arrayref',
);

is(
	exception { Example1::->new( my_hash => { '' => undef } ) },
	undef,
	'non-empty hashref, okay',
);

isa_ok(
	exception { Example1::->new( my_hash => +{} ) },
	'Error::TypeTiny',
	'result of empty hashref',
);

done_testing;
