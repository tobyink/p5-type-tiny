=pod

=encoding utf-8

=head1 PURPOSE

Checks union type constraints throw sane error messages.

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
use Type::Tiny::Union;

like(
	exception { Type::Tiny::Union->new(parent => Int) },
	qr/^Union type constraints cannot have a parent constraint/,
);

like(
	exception { Type::Tiny::Union->new(constraint => sub { 1 }) },
	qr/^Union type constraints cannot have a constraint coderef/,
);

like(
	exception { Type::Tiny::Union->new(inlined => sub { 1 }) },
	qr/^Union type constraints cannot have a inlining coderef/,
);

like(
	exception { Type::Tiny::Union->new() },
	qr/^Need to supply list of type constraints/,
);

my $e = exception {
	Type::Tiny::Union
		->new(name => "Elsa", type_constraints => [Int, ArrayRef[Int]])
		->assert_valid( 3.14159 );
};

is_deeply(
	$e->explain,
	[
		'"Int|ArrayRef[Int]" requires that the value pass "ArrayRef[Int]" or "Int"',
		'Value "3.14159" did not pass type constraint "Int"',
		'    Value "3.14159" did not pass type constraint "Int"',
		'    "Int" is defined as: (do { my $tmp = $_; defined($tmp) and !ref($tmp) and $tmp =~ /\\A-?[0-9]+\\z/ })',
		'Value "3.14159" did not pass type constraint "ArrayRef[Int]"',
		'    "ArrayRef[Int]" is a subtype of "ArrayRef"',
		'    "ArrayRef" is a subtype of "Ref"',
		'    Value "3.14159" did not pass type constraint "Ref"',
		'    "Ref" is defined as: (!!ref($_))',
	],
) or diag explain($e->explain);

done_testing;
