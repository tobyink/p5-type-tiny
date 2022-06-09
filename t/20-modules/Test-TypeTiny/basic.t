=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Test::TypeTiny> (which is somewhat important because
Test::TypeTiny is itself used for the majority of the type constraint
tests).

In particular, this tests that everything works when the
C<< $EXTENDED_TESTING >> environment variable is false.

=head1 DEPENDENCIES

Requires L<Test::Tester> 0.109.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

BEGIN
{
	$ENV{EXTENDED_TESTING} = 0;
	
	if (eval { require Test::Tester })
	{
		Test::Tester->import(tests => 48);
	}
	else
	{
		require Test::More;
		Test::More->import(skip_all => 'requires Test::Tester');
	}
}

use Test::TypeTiny;
use Types::Standard qw( Int Num );

check_test(
	sub { should_pass(1, Int) },
	{
		ok    => 1,
		name  => 'Value "1" passes type constraint Int',
		diag  => '',
		type  => '',
	},
	'successful should_pass',
);

check_test(
	sub { should_pass([], Int) },
	{
		ok    => 0,
		name  => 'Reference [] passes type constraint Int',
		diag  => '',
		type  => '',
	},
	'unsuccessful should_pass',
);

check_test(
	sub { should_fail([], Int) },
	{
		ok    => 1,
		name  => 'Reference [] fails type constraint Int',
		diag  => '',
		type  => '',
	},
	'successful (i.e. failing) should_fail',
);

check_test(
	sub { should_fail(1, Int) },
	{
		ok    => 0,
		name  => 'Value "1" fails type constraint Int',
		diag  => '',
		type  => '',
	},
	'unsuccessful (i.e. passing) should_fail',
);

check_test(
	sub { ok_subtype(Num, Int) },
	{
		ok    => 1,
		name  => 'Num subtype: Int',
		diag  => '',
		type  => '',
	},
	'successful ok_subtype',
);

check_test(
	sub { ok_subtype(Int, Num) },
	{
		ok    => 0,
		name  => 'Int subtype: Num',
		diag  => '',
		type  => '',
	},
	'unsuccessful ok_subtype',
);
