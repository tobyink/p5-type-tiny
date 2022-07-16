=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params>' brand spanking new C<compile_named> function.

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
use Test::Fatal;

use Type::Params qw(compile_named);
use Types::Standard qw(Int);

subtest "predictable error message when problems with two parameters" => sub {
	for my $i (1..20) {
		my $check1 = compile_named( a => Int, b => Int );
		my $check2 = compile_named( b => Int, a => Int );
		like(
			exception { $check1->( c => 1, c => 1 ) },
			qr/Missing required parameter: a/,
			"Iteration $i, check 1, missing parameters",
		);
		like(
			exception { $check1->(a => [], b => {}) },
			qr/Reference \[\] did not pass type constraint "Int"/,
			"Iteration $i, check 1, invalid values",
		);
		like(
			exception { $check1->(a => 1, b => 2, c => '3PO', r2d => 2) },
			qr/(Unrecognized parameters: c and r2d)|(Wrong number of parameters)/,
			"Iteration $i, check 1, extra values",
		);
		like(
			exception { $check2->() },
			qr/(Missing required parameter: b)|(Wrong number of parameters)/,
			"Iteration $i, check 2, missing parameters",
		);
		like(
			exception { $check2->(a => [], b => {}) },
			qr/Reference \{\} did not pass type constraint "Int"/,
			"Iteration $i, check 2, invalid values",
		);
		like(
			exception { $check2->(a => 1, b => 2, c => '3PO', r2d => 2) },
			qr/(Unrecognized parameters: c and r2d)|(Wrong number of parameters)/,
			"Iteration $i, check 2, extra values",
		);
	}
};

done_testing;
