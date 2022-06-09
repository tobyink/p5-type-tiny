=pod

=encoding utf-8

=head1 PURPOSE

Test for non-inlined coercions in Moo.

The issue that prompted this test was actually invalid, caused by a typo
in the bug reporter's code. But I wrote the test case, so I might as well
include it.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/14>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires { Moo => '1.006' };

{
	package FinancialTypes;
	use Type::Library -base;
	use Type::Utils -all;
	BEGIN { extends "Types::Standard" };
	
	declare 'BankAccountNo',
		as Str,
		where {
			/^\d{26}$/
			or /^[A-Z]{2}\d{18,26}$/
			or /^\d{8}-\d+(-\d+)+$/
		},
		message { "Bad account: $_"};
		
		coerce 'BankAccountNo',
			from Str, via {
				$_ =~ s{\s+}{}g;
				$_;
			};
}

{
	package BankAccount;
	use Moo;
	has account_number => (
		is        => 'ro',
		required  => !!1,
		isa       => FinancialTypes::BankAccountNo(),
		coerce    => FinancialTypes::BankAccountNo()->coercion,
	);
}

my $x;
my $e = exception {
	$x = BankAccount::->new( account_number => "10 2030 4050 1111 2222 3333 4444" );
};
is($e, undef);
is($x->account_number, "10203040501111222233334444");
done_testing();
