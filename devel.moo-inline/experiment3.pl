use v5.14;

package Foo {
	use Moo;
	use Types::Standard qw(HashRef);
	has foo => (is => "ro", isa => HashRef);
}

say Foo->new( foo => [] )->foo;

