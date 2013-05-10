=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Type::Exception>.

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

use Test::More;
use Test::Fatal;

use Types::Standard qw(Int);

my $v = [];
my $e = exception { Int->create_child_type->assert_valid($v) };

isa_ok($e, "Type::Exception", '$e');

is(
	$e->message,
	q{[] did not pass type constraint},
	'$e->message is as expected',
);

isa_ok($e, "Type::Exception::Assertion", '$e');

cmp_ok(
	$e->type, '==', Int,
	'$e->type is as expected',
);

is(
	$e->value,
	$v,
	'$e->value is as expected',
);


is_deeply(
	$e->explain,
	[
		'__ANON__ is a subtype of Int',
		'Int is a subtype of Num',
		'Num is a subtype of Str',
		'Str is a subtype of Value',
		'[] fails type constraint Value',
		'Value is defined as: (defined($_) and not ref($_))',
	],
	'$e->explain is as expected',
);

done_testing;
