=pod

=encoding utf-8

=head1 PURPOSE

Checks intersection type constraints throw sane error messages.

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
use Test::Fatal;

use Types::Standard qw(Int ArrayRef);
use Type::Tiny::Intersection;

like(
	exception { Type::Tiny::Intersection->new(parent => Int) },
	qr/^Intersection type constraints cannot have a parent constraint/,
);

like(
	exception { Type::Tiny::Intersection->new(constraint => sub { 1 }) },
	qr/^Intersection type constraints cannot have a constraint coderef/,
);

like(
	exception { Type::Tiny::Intersection->new(inlined => sub { 1 }) },
	qr/^Intersection type constraints cannot have a inlining coderef/,
);

like(
	exception { Type::Tiny::Intersection->new() },
	qr/^Need to supply list of type constraints/,
);

my $e = exception {
	Type::Tiny::Intersection
		->new(name => "Elsa", type_constraints => [Int, Int])
		->assert_valid( 3.14159 );
};

is_deeply(
	$e->explain,
	[
		'"Int&Int" requires that the value pass "Int" and "Int"',
		'Value "3.14159" did not pass type constraint "Int"',
		'"Int" is defined as: (do { my $tmp = $_; defined($tmp) and !ref($tmp) and $tmp =~ /\\A-?[0-9]+\\z/ })',
	],
) or diag explain($e->explain);

done_testing;
