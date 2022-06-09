=pod

=encoding utf-8

=head1 PURPOSE

Test the L<Types::TypeTiny> introspection methods. Types::TypeTiny doesn't
inherit from L<Type::Library> (because bootstrapping), so provides
independent re-implementations of the most important introspection stuff.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny -all;
use Types::TypeTiny;

my $meta = Types::TypeTiny->meta;

is_deeply(
	[ sort $meta->type_names ],
	[ sort qw( CodeLike ArrayLike StringLike HashLike TypeTiny _ForeignTypeConstraint ) ],
	'type_names',
);

ok(
	$meta->has_type('HashLike'),
	'has_type(HashLike)',
);

ok(
	$meta->get_type('HashLike')->equals(Types::TypeTiny::HashLike()),
	'get_type(HashLike)',
);

ok(
	!$meta->has_type('MonkeyNuts'),
	'has_type(MonkeyNuts)',
);

ok(
	!defined( $meta->get_type('MonkeyNuts') ),
	'get_type(MonkeyNuts)',
);

is_deeply(
	[ sort $meta->coercion_names ],
	[],
	'coercion_names',
);

ok(
	!$meta->has_coercion('MonkeyNuts'),
	'has_coercion(MonkeyNuts)',
);

ok(
	!defined( $meta->get_coercion('MonkeyNuts') ),
	'get_coercion(MonkeyNuts)',
);

done_testing;
