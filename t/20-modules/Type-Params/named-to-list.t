=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with named parameters and
C<named_to_list>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard qw(Int);
use Type::Params qw(compile_named);

my $check1 = compile_named(
	{ named_to_list => 1 },
	foo => Int,
	bar => Int,
);
is_deeply(
	[$check1->(foo => 1, bar => 2)],
	[1, 2],
);
is_deeply(
	[$check1->(bar => 2, foo => 1)],
	[1, 2],
);
is_deeply(
	[$check1->(bar => 2, foo => 99)],
	[99, 2],
);

my $check2 = compile_named(
	{ named_to_list => 1 },
	foo => Int,
	bar => Int,
	baz => Int, { optional => 1 },
);
is_deeply(
	[$check2->(foo => 1, bar => 2)],
	[1, 2, undef],
);
is_deeply(
	[$check2->(bar => 2, foo => 1)],
	[1, 2, undef],
);
is_deeply(
	[$check2->(bar => 2, foo => 99)],
	[99, 2, undef],
);
is_deeply(
	[$check2->(baz => 666, foo => 1, bar => 2)],
	[1, 2, 666],
);
is_deeply(
	[$check2->(bar => 2, baz => 666, foo => 1)],
	[1, 2, 666],
);
is_deeply(
	[$check2->(bar => 2, foo => 99, baz => 666)],
	[99, 2, 666],
);

my $check3 = compile_named(
	{ named_to_list => [qw(baz bar)] },
	foo => Int,
	bar => Int,
	baz => Int, { optional => 1 },
);
is_deeply(
	[$check3->(foo => 1, bar => 2)],
	[undef, 2],
);
is_deeply(
	[$check3->(bar => 2, foo => 1)],
	[undef, 2],
);
is_deeply(
	[$check3->(bar => 2, foo => 99)],
	[undef, 2],
);
is_deeply(
	[$check3->(baz => 666, foo => 1, bar => 2)],
	[666, 2],
);
is_deeply(
	[$check3->(bar => 2, baz => 666, foo => 1)],
	[666, 2],
);
is_deeply(
	[$check3->(bar => 2, foo => 99, baz => 666)],
	[666, 2],
);

done_testing;
