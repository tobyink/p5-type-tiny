=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints work in L<Moops>.

This file is borrowed from the Moops test suite, where it is called
C<< 31types.t >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires 'Moops';
use Test::Fatal;

use Moops;

class Foo {
	has num => (is => 'rw', isa => Num);
	method add ( Num $addition ) {
		$self->num( $self->num + $addition );
	}
}

my $foo = 'Foo'->new(num => 20);
is($foo->num, 20);
is($foo->num(40), 40);
is($foo->num, 40);
is($foo->add(2), 42);
is($foo->num, 42);

isnt(
	exception { $foo->num("Hello") },
	undef,
);

isnt(
	exception { $foo->add("Hello") },
	undef,
);

isnt(
	exception { 'Foo'->new(num => "Hello") },
	undef,
);

done_testing;
