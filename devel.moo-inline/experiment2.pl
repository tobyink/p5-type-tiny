use v5.14;

use Types::Standard -types;

package Type::Tiny {
	no warnings "redefine";
	use overload q(&{}) => sub {
		require Sub::Quote;
		my $t = shift;
		return Sub::Quote::quote_sub($t->inline_assert('$_[0]'));
	};
	sub inline_assert {
		"die 'YEEHAA!' unless ".shift->inline_check(@_);
	}
}

package Foo {
	use Moo;
	has foo => (is => "ro", isa => Types::Standard::HashRef);
}

say Foo->new( foo => [] )->foo;

