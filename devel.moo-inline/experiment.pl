use v5.14;

use Types::Standard -types;

$Sub::Quote::WEAK_REFS{+HashRef} = $Sub::Quote::QUOTED{+HashRef} = ["HashRef", HashRef->inline_assert('$_[0]')];

package Type::Tiny {
	sub inline_assert {
		"die 'YEEHAA!' unless ".shift->inline_check(@_);
	}
}

package Foo {
	use Moo;
	has foo => (is => "ro", isa => Types::Standard::HashRef);
}

say Foo->new( foo => [] )->foo;

