=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Test::TypeTiny> works when the C<< $EXTENDED_TESTING >>
environment variable is true.

Note that L<Test::Tester> appears to have issues with subtests,
so currently C<should_pass> and C<should_fail> are not tested.

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
	$ENV{EXTENDED_TESTING} = 1;
	
	if (eval { require Test::Tester })
	{
		Test::Tester->import(tests => 16);
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
