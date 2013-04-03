=pod

=encoding utf-8

=head1 PURPOSE

Checks that the coercion functions exported by a type library work as expected.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Fatal qw(dies_ok);

use BiggerLib qw(:to);

is(
	to_BigInteger(8),
	18,
	'to_BigInteger converts a small integer OK'
);

is(
	to_BigInteger(17),
	17,
	'to_BigInteger leaves an existing BigInteger OK'
);

is(
	to_BigInteger(3.14),
	3.14,
	'to_BigInteger ignores something it cannot coerce'
);

my $new_type = BiggerLib::BigInteger->plus_coercions(
	BiggerLib::HashRef, sub { 999 },
	BiggerLib::Undef,   sub { 666 },
);
my $arr  = [];
my $hash = {};

ok(
	$new_type->coercion->has_coercion_for_type(BiggerLib::HashRef),
	'has_coercian_for_type - obvious',
);

ok(
	$new_type->coercion->has_coercion_for_type(BiggerLib::HashRef[BiggerLib::Num]),
	'has_coercian_for_type - subtle',
);

ok(
	not($new_type->coercion->has_coercion_for_type(BiggerLib::Ref["CODE"])),
	'has_coercian_for_type - negative',
);

is($new_type->coerce($hash), 999, 'plus_coercions - added coercion');
is($new_type->coerce(undef), 666, 'plus_coercions - added coercion');
is($new_type->coerce(-1), 11, 'plus_coercions - retained coercion');
is($new_type->coerce($arr), 100, 'plus_coercions - retained coercion');

my $newer_type = $new_type->minus_coercions(BiggerLib::ArrayRef, BiggerLib::Undef);
is($newer_type->coerce($hash), 999, 'minus_coercions - retained coercion');
is($newer_type->coerce(undef), undef, 'minus_coercions - removed coercion');
is($newer_type->coerce(-1), 11, 'minus_coercions - retained coercion');
is($newer_type->coerce($arr), $arr, 'minus_coercions - removed coercion');

$newer_type->coercion->_build_compiled_coercion;

my $no_coerce = $new_type->no_coercions;
dies_ok { $no_coerce->coerce($hash) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce(undef) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce(-1) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce($arr) } 'no_coercions - removed coercion';

done_testing;
