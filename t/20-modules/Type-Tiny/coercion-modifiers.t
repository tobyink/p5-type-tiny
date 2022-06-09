=pod

=encoding utf-8

=head1 PURPOSE

Checks C<plus_coercions>, C<minus_coercions> and C<no_coercions> methods work.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

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

use Test::More;
use Test::Fatal qw(dies_ok);

use BiggerLib -types;

my $new_type = BigInteger->plus_coercions(
	HashRef, "999",
	Undef,   sub { 666 },
);
my $arr  = [];
my $hash = {};

ok(
	$new_type->coercion->has_coercion_for_type(HashRef),
	'has_coercian_for_type - obvious',
);

ok(
	$new_type->coercion->has_coercion_for_type(HashRef[Num]),
	'has_coercian_for_type - subtle',
);

ok(
	not($new_type->coercion->has_coercion_for_type(Ref["CODE"])),
	'has_coercian_for_type - negative',
);

is($new_type->coerce($hash), 999, 'plus_coercions - added coercion');
is($new_type->coerce(undef), 666, 'plus_coercions - added coercion');
is($new_type->coerce(-1), 11, 'plus_coercions - retained coercion');
is($new_type->coerce($arr), 100, 'plus_coercions - retained coercion');

my $newer_type = $new_type->minus_coercions(ArrayRef, Undef);
is($newer_type->coerce($hash), 999, 'minus_coercions - retained coercion');
is($newer_type->coerce(undef), undef, 'minus_coercions - removed coercion');
is($newer_type->coerce(-1), 11, 'minus_coercions - retained coercion');
is($newer_type->coerce($arr), $arr, 'minus_coercions - removed coercion');

my $no_coerce = $new_type->no_coercions;
dies_ok { $no_coerce->coerce($hash) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce(undef) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce(-1) } 'no_coercions - removed coercion';
dies_ok { $no_coerce->coerce($arr) } 'no_coercions - removed coercion';

done_testing;
