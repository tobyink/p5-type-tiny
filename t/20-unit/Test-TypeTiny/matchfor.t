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

This software is copyright (c) 2014, 2017 by Toby Inkster.

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
		require Test::More;
		Test::Tester->import(tests => 24);
	}
	else
	{
		require Test::More;
		Test::More->import(skip_all => 'requires Test::Tester');
	}
}

use Test::TypeTiny qw(matchfor);

check_test(
	sub {
		Test::More::is(
			"Hello world",
			matchfor(qr/hello/i, qr/hiya/i, "Greeting::Global"),
			'Yahoo',
		);
	},
	{
		ok    => 1,
		name  => 'Yahoo',
		diag  => '',
		type  => '',
	},
	'successful matchfor(qr//)',
);

check_test(
	sub {
		Test::More::is(
			"Hiya world",
			matchfor(qr/hello/i, qr/hiya/i, "Greeting::Global"),
			'Yahoo',
		);
	},
	{
		ok    => 1,
		name  => 'Yahoo',
		diag  => '',
		type  => '',
	},
	'successful matchfor(qr//)',
);

check_test(
	sub {
		Test::More::is(
			bless({}, "Greeting::Global"),
			matchfor(qr/hello/i, qr/hiya/i, "Greeting::Global"),
			'Yahoo',
		);
	},
	{
		ok    => 1,
		name  => 'Yahoo',
		diag  => '',
		type  => '',
	},
	'successful matchfor(CLASS)',
);
