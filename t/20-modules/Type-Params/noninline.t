=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> with type constraints that cannot be inlined.

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
use Types::Standard qw(Num ArrayRef);
use Type::Utils;

my $NumX = declare NumX => as Num, where { $_ != 42 };

my $check;
sub nth_root
{
	$check ||= compile( $NumX, $NumX );
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
	like($e, qr{^Wrong number of parameters; got 0; expected 2}, '()');
}

{
	my $e = exception { nth_root(1) };
	like($e, qr{^Wrong number of parameters; got 1; expected 2}, '(1)');
}

{
	my $e = exception { nth_root(undef, 1) };
	like($e, qr{^Undef did not pass type constraint "NumX" \(in \$_\[0\]\)}, '(undef, 1)');
}

{
	my $e = exception { nth_root(41, 42) };
	like($e, qr{^Value "42" did not pass type constraint "NumX" \(in \$_\[1\]\)}, '(42)');
}

my $check2;
sub nth_root_coerce
{
	$check2 ||= compile(
		$NumX->plus_coercions(
			Num,      sub { 21 },            # non-inline
			ArrayRef, q   { scalar(@$_) },   # inline
		),
		$NumX,
	);
	[ $check2->(@_) ];
}

is_deeply(
	nth_root_coerce(42, 11),
	[21, 11],
	'(42, 11)'
);

is_deeply(
	nth_root_coerce([1..3], 11),
	[3, 11],
	'([1..3], 11)'
);

{
	my $e = exception { nth_root_coerce([1..41], 42) };
	like($e, qr{^Value "42" did not pass type constraint "NumX" \(in \$_\[1\]\)}, '([1..41], 42)');
}

done_testing;

