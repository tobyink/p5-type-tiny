=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<OptList> from Types::Standard.

Checks the standalone C<MkOpt> coercion.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Types::Standard qw( OptList MkOpt );

my $O  = OptList;
my $OM = OptList->plus_coercions(MkOpt);

should_pass([], $O);
should_pass([[foo=>undef]], $O);
should_pass([[foo=>[]]], $O);
should_pass([[foo=>{}]], $O);
should_pass([], $OM);
should_pass([[foo=>undef]], $OM);
should_pass([[foo=>[]]], $OM);
should_pass([[foo=>{}]], $OM);

should_fail([[undef]], $O);
should_fail([[[]]], $O);
should_fail([[{}]], $O);
should_fail([[undef]], $OM);
should_fail([[[]]], $OM);
should_fail([[{}]], $OM);

ok(!$O->has_coercion, "not $O has coercion");
ok($OM->has_coercion, "$OM has coercion");

is_deeply(
	$OM->coerce(undef),
	[],
	'$OM->coerce(undef)',
);

is_deeply(
	$OM->coerce([]),
	[],
	'$OM->coerce([])',
);

is_deeply(
	$OM->coerce([foo => {}, bar => "baz"]),
	[
		[foo => {}],
		[bar => undef],
		[baz => undef],
	],
	'simple $OM coercion test',
);

is_deeply(
	$OM->coerce({foo => []}),
	[
		[foo => []],
	],
	'another simple $OM coercion test',
);

done_testing;
