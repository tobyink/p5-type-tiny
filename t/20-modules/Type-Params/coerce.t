=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage of types with coercions.

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

use Type::Params qw(compile);
use Types::Standard -types, "slurpy";
use Type::Utils;
use Scalar::Util qw(refaddr);

my $RoundedInt = declare as Int;
coerce $RoundedInt, from Num, q{ int($_) };

my $chk = compile(Int, $RoundedInt, Num);

is_deeply(
	[ $chk->(1, 2, 3.3) ],
	[ 1, 2, 3.3 ]
);

is_deeply(
	[ $chk->(1, 2.2, 3.3) ],
	[ 1, 2, 3.3 ]
);

like(
	exception { $chk->(1.1, 2.2, 3.3) },
	qr{^Value "1\.1" did not pass type constraint "Int" \(in \$_\[0\]\)},
);

my $chk2 = compile(ArrayRef[$RoundedInt]);

is_deeply(
	[ $chk2->([1, 2, 3]) ],
	[ [1, 2, 3] ]
);

is_deeply(
	[ $chk2->([1.1, 2.2, 3.3]) ],
	[ [1, 2, 3] ]
);

is_deeply(
	[ $chk2->([1.1, 2, 3.3]) ],
	[ [1, 2, 3] ]
);

my $arr  = [ 1 ];
my $arr2 = [ 1.1 ];

is(
	refaddr( [$chk2->($arr)]->[0] ),
	refaddr($arr),
	'if value passes type constraint; no need to clone arrayref'
);

isnt(
	refaddr( [$chk2->($arr2)]->[0] ),
	refaddr($arr2),
	'if value fails type constraint; need to clone arrayref'
);

my $chk3 = compile($RoundedInt->no_coercions);

like(
	exception { $chk3->(1.1) },
	qr{^Value "1\.1" did not pass type constraint},
);

done_testing;
