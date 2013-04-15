=pod

=encoding utf-8

=head1 PURPOSE

Type::Coercion objects are mutable, unlike Type::Tiny objects.

However, they can be frozen, making them immutable. (And Type::Tiny will
freeze them occasionally, if it feels it has to.)

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Requires Moose 2.0000

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::Requires { Moose => 2.0000 };
use Test::More;
use Test::Fatal;

use BiggerLib -types;

ok(!BigInteger->coercion->frozen, 'coercions are not initially frozen');

BigInteger->coercion->add_type_coercions(Any, sub { 777 });

ok(!BigInteger->coercion->frozen, 'coercions do not freeze because of adding code');

BigInteger->coercion->moose_coercion;

ok(BigInteger->coercion->frozen, 'coercions do freeze when forced inflation to Moose');

my $e = exception {
	BigInteger->coercion->add_type_coercions(Item, sub { 888 })
};

like($e, qr{Attempt to add coercion code to a Type::Coercion which has been frozen}, 'cannot add code to a frozen coercion');

done_testing;
