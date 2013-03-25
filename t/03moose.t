use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Requires Moose => 2.00;
use Test::Fatal;

{
	package Local::Class;
	
	use Moose;
	use BiggerLib -moose, -all;
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

is(
	exception { "Local::Class"->new(small => 9, big => 12) },
	undef,
	"some values that should pass their type constraint",
);

like(
	exception { "Local::Class"->new(small => 100) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"direct violation of type constraint",
);

like(
	exception { "Local::Class"->new(small => 5.5) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of parent type constraint",
);

like(
	exception { "Local::Class"->new(small => "five point five") },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of grandparent type constraint",
);

like(
	exception { "Local::Class"->new(small => []) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of great-grandparent type constraint",
);

done_testing;
