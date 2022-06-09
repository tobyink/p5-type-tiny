=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with optional parameters.

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
use Types::Standard -types;

my $chk1 = compile(Num, Optional[Int], Optional[ArrayRef], Optional[HashRef]);
my $chk2 = compile(Num, Int, {optional=>1}, ArrayRef, {optional=>1}, HashRef, {optional=>1});
my $chk3 = compile(Num, Int, {optional=>1}, Optional[ArrayRef], HashRef, {optional=>1});
my $chk4 = compile(Num, Int, {optional=>1}, Optional[ArrayRef], {optional=>1}, HashRef, {optional=>1});
my $chk5 = compile(Num, {optional=>0}, Optional[Int], Optional[ArrayRef], Optional[HashRef]);

for my $chk ($chk1, $chk2, $chk3, $chk4, $chk5) {
	is_deeply(
		[ $chk->(1.1, 2, [], {}) ],
		[ 1.1, 2, [], {} ]
	);

	is_deeply(
		[ $chk->(1.1, 2, []) ],
		[ 1.1, 2, [] ]
	);

	is_deeply(
		[ $chk->(1.1, 2) ],
		[ 1.1, 2 ]
	);

	is_deeply(
		[ $chk->(1.1) ],
		[ 1.1 ]
	);

	like(
		exception { $chk->(1.1, 2, {}) },
		qr{^Reference \{\} did not pass type constraint "(Optional\[)?ArrayRef\]?" \(in \$_\[2\]\)},
	);

	like(
		exception { $chk->() },
		qr{^Wrong number of parameters; got 0; expected 1 to 4},
	);

	like(
		exception { $chk->(1 .. 5) },
		qr{^Wrong number of parameters; got 5; expected 1 to 4},
	);
	
	like(
		exception { $chk->(1, 2, undef) },
		qr{^Undef did not pass type constraint},
	);
}

my $chk99 = compile(1, 0, 0);
like(
	exception { $chk99->() },
	qr{^Wrong number of parameters; got 0; expected 1 to 3},
);

done_testing;

