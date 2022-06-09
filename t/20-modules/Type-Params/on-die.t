=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> support for C<on_die>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw( compile compile_named );
use Types::Standard -types, "slurpy";

subtest "compile" => sub {
	my ( $E, @R );
	my $coderef = compile(
		{ on_die => sub { $E = shift; 'XXX' } },
		Int,
	);

	is(
		exception { @R = $coderef->("foo") },
		undef,
		'No exception thrown',
	);

	is_deeply(
		\@R,
		[ 'XXX' ],
		'Correct value returned',
	);

	is(
		$E->type->name,
		'Int',
		'Passed exception to callback',
	);
};

subtest "compile_named" => sub {
	my ( $E, @R );
	my $coderef = compile_named(
		{ on_die => sub { $E = shift; 'XXX' } },
		foo => Int,
	);

	is(
		exception { @R = $coderef->(foo => "foo") },
		undef,
		'No exception thrown',
	);

	is_deeply(
		\@R,
		[ 'XXX' ],
		'Correct value returned',
	);

	is(
		$E->type->name,
		'Int',
		'Passed exception to callback',
	);
};

done_testing;
