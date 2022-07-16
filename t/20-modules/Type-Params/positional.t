=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> positional parameters, a la the example in the
documentation:

   sub nth_root
   {
      state $check = compile( Num, Num );
      my ($x, $n) = $check->(@_);
      
      return $x ** (1 / $n);
   }

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
use Types::Standard -types, 'slurpy';

{
	my $e = exception { compile()->(1) };
	like($e, qr{^Wrong number of parameters; got 1; expected 0}, 'empty compile()');
}

my $check;
sub nth_root
{
	$check ||= compile( Num, Num );
	[ $check->(@_) ];
}

is_deeply(
	nth_root(1, 2),
	[ 1, 2 ],
	'(1, 2)',
);

is_deeply(
	nth_root("1.1", 2),
	[ "1.1", 2 ],
	'(1.1, 2)',
);

{
	my $e = exception { nth_root() };
	like($e, qr{^Wrong number of parameters; got 0; expected 2}, '(1)');
}

{
	my $e = exception { nth_root(1) };
	like($e, qr{^Wrong number of parameters; got 1; expected 2}, '(1)');
}

{
	my $e = exception { nth_root(undef, 1) };
	like($e, qr{^Undef did not pass type constraint "Num" \(in \$_\[0\]\)}, '(undef, 1)');
}

{
	my $e = exception { nth_root(1, 2, 3) };
	like($e, qr{^Wrong number of parameters; got 3; expected 2}, '(1)');
}

my $fooble_check;
sub fooble {
	$fooble_check = compile(
		{
			head => [ ArrayRef, CodeRef ],
			tail => [ HashRef, ScalarRef, Int->plus_coercions(Num, q{int $_}) ],
		},
		Num,
		slurpy ArrayRef[Int],
	);
	$fooble_check->(@_);
}

my $random_code = sub {};

is_deeply(
	[ fooble( [1], $random_code, 1.1, 1, 2, 3, 4, { foo=>1 }, \42, 1.2 ) ],
	[ [1], $random_code, 1.1, [1, 2, 3, 4], { foo=>1 }, \42, 1 ],
	'head and tail work',
);

like(
	exception { fooble() },
	qr/got 0; expected at least 6/,
);

like(
	exception { fooble([]) },
	qr/got 1; expected at least 6/,
);

like(
	exception { fooble( undef, $random_code, 1.1, 1, 2, 3, 4, { foo=>1 }, \42, 1.2 ) },
	qr/^Undef did not pass type constraint "ArrayRef" \(in \$_\[0\]\)/,
);

like(
	exception { fooble( [1], undef, 1.1, 1, 2, 3, 4, { foo=>1 }, \42, 1.2 ) },
	qr/^Undef did not pass type constraint "CodeRef" \(in \$_\[1\]\)/,
);

like(
	exception { fooble( [1], $random_code, undef, 1, 2, 3, 4, { foo=>1 }, \42, 1.2 ) },
	qr/^Undef did not pass type constraint "Num" \(in \$_\[2\]\)/,
);

like(
	exception { fooble( [1], $random_code, 1.1, 1, 2, 3, 4, undef, \42, 1.2 ) },
	qr/^Undef did not pass type constraint "HashRef" \(in \$_\[-3\]\)/,
);

like(
	exception { fooble( [1], $random_code, 1.1, 1, 2, 3, 4, { foo=>1 }, undef, 1.2 ) },
	qr/^Undef did not pass type constraint "ScalarRef" \(in \$_\[-2\]\)/,
);

like(
	exception { fooble( [1], $random_code, 1.1, 1, 2, 3, 4, { foo=>1 }, \42, undef ) },
	qr/Undef did not pass type constraint "Int" \(in \$_\[-1\]\)/,
);

like(
	exception { fooble( [1], $random_code, 1.1, 1, undef, 3, 4, { foo=>1 }, \42, 1.2 ) },
	qr/did not pass type constraint/,
);

done_testing;

