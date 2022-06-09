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

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

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

BigInteger->coercion->add_type_coercions(Undef, sub { 777 });

ok(!BigInteger->coercion->frozen, 'coercions do not freeze because of adding code');

is(BigInteger->coerce(undef), 777, '... and they work');

BigInteger->coercion->moose_coercion;

ok(BigInteger->coercion->frozen, 'coercions do freeze when forced inflation to Moose');

my $e = exception {
	BigInteger->coercion->add_type_coercions(Item, sub { 999 })
};

like($e, qr{Attempt to add coercion code to a Type::Coercion which has been frozen}, 'cannot add code to a frozen coercion');

BigInteger->coercion->i_really_want_to_unfreeze;

ok(!BigInteger->coercion->frozen, 'i_really_want_to_unfreeze');

$e = exception {
	BigInteger->coercion->add_type_coercions(Item, sub { 888 })
};

is($e, undef, '... can now add coercions');
is(BigInteger->coerce(\$e), 888, '... ... which work');

done_testing;
