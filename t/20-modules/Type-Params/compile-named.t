=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params>' brand spanking new C<compile_named> function.

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

use Type::Params qw(compile_named validate_named);
use Types::Standard -types, "slurpy";
use Type::Utils;
use Scalar::Util qw(refaddr);

{
	my $e = exception { compile_named()->(foo => 1) };
	like($e, qr{^Wrong number of parameters});
}

{
	package
	Type::Tiny::_Test::X;
	sub new { bless $_[1], $_[0] }
}

sub simple_test {
	my ($name, @spec) = @_;
	
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	subtest $name => sub {
		_simple_test( validate_named => sub { validate_named(\@_, @spec) } );
		_simple_test( compile_named  => compile_named(@spec) );
	};
}

sub slurpy_test {
	my ($name, @spec) = @_;
	
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	subtest $name => sub {
		_slurpy_test( validate_named => sub { validate_named(\@_, @spec) } );
		_slurpy_test( compile_named  => compile_named(@spec) );
	};
}

sub _simple_test {
	my ($name, $check) = @_;
	
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	subtest $name, sub
	{
		is_deeply(
			$check->( foo => 3, bar => 42 ),
			{ foo => 3, bar => 42 },
			'accept a hash',
		);
		
		is_deeply(
			$check->( foo => 3, bar => 42, baz => [1..3] ),
			{ foo => 3, bar => 42, baz => [1..3] },
			'accept a hash, with optional parameter',
		);
		
		is_deeply(
			$check->( foo => 3.1, bar => 42 ),
			{ foo => 3, bar => 42 },
			'accept a hash, and coerce',
		);
		
		is_deeply(
			$check->( foo => 3.1, bar => 42, baz => [1..3, 4.2] ),
			{ foo => 3, bar => 42, baz => [1..4] },
			'accept a hash, with optional parameter, and coerce',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42 }),
			{ foo => 3, bar => 42 },
			'accept a hashref',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42, baz => [1..3] }),
			{ foo => 3, bar => 42, baz => [1..3] },
			'accept a hashref, with optional parameter',
		);
		
		is_deeply(
			$check->({ foo => 3.1, bar => 42 }),
			{ foo => 3, bar => 42 },
			'accept a hashref, and coerce',
		);
		
		is_deeply(
			$check->({ foo => 3.1, bar => 42, baz => [1..3, 4.2] }),
			{ foo => 3, bar => 42, baz => [1..4] },
			'accept a hashref, with optional parameter, and coerce',
		);
		
		like(
			exception { $check->({ foo => [], bar => 42 }) },
			qr/^Reference \[\] did not pass type constraint/,
			'bad "foo" parameter',
		);
		
		like(
			exception { $check->({ foo => 3, bar => [] }) },
			qr/^Reference \[\] did not pass type constraint/,
			'bad "bar" parameter',
		);
		
		like(
			exception { $check->({ foo => {}, bar => [] }) },
			qr/^Reference \{\} did not pass type constraint/,
			'two bad parameters; "foo" throws before "bar" gets a chance',
		);
		
		like(
			exception { $check->({ foo => 3, bar => 42, baz => {} }) },
			qr/^Reference \{\} did not pass type constraint/,
			'bad optional "baz" parameter',
		);
		
		like(
			exception { $check->({ foo => 3, bar => 42, xxx => 1 }) },
			qr/^Unrecognized parameter: xxx/,
			'additional parameter',
		);
		
		like(
			exception { $check->({ foo => 3, bar => 42, xxx => 1, yyy => 2, zzz => 3 }) },
			qr/^Unrecognized parameters: xxx, yyy, zzz/,
			'additional parameters',
		);
		
		like(
			exception { $check->({ }) },
			qr/^Missing required parameter: foo/,
			'missing parameter',
		);
	};
}

sub _slurpy_test {
	my ($name, $check) = @_;
	
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	subtest $name, sub
	{
		is_deeply(
			$check->( foo => 3, bar => 42 ),
			{ XXX => {}, foo => 3, bar => 42 },
			'accept a hash',
		);
		
		is_deeply(
			$check->( foo => 3, bar => 42, baz => [1..3] ),
			{ XXX => {}, foo => 3, bar => 42, baz => [1..3] },
			'accept a hash, with optional parameter',
		);
		
		is_deeply(
			$check->( foo => 3.1, bar => 42 ),
			{ XXX => {}, foo => 3, bar => 42 },
			'accept a hash, and coerce',
		);
		
		is_deeply(
			$check->( foo => 3.1, bar => 42, baz => [1..3, 4.2] ),
			{ XXX => {}, foo => 3, bar => 42, baz => [1..4] },
			'accept a hash, with optional parameter, and coerce',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42 }),
			{ XXX => {}, foo => 3, bar => 42 },
			'accept a hashref',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42, baz => [1..3] }),
			{ XXX => {}, foo => 3, bar => 42, baz => [1..3] },
			'accept a hashref, with optional parameter',
		);
		
		is_deeply(
			$check->({ foo => 3.1, bar => 42 }),
			{ XXX => {}, foo => 3, bar => 42 },
			'accept a hashref, and coerce',
		);
		
		is_deeply(
			$check->({ foo => 3.1, bar => 42, baz => [1..3, 4.2] }),
			{ XXX => {}, foo => 3, bar => 42, baz => [1..4] },
			'accept a hashref, with optional parameter, and coerce',
		);
		
		like(
			exception { $check->({ foo => [], bar => 42 }) },
			qr/^Reference \[\] did not pass type constraint/,
			'bad "foo" parameter',
		);
		
		like(
			exception { $check->({ foo => 3, bar => [] }) },
			qr/^Reference \[\] did not pass type constraint/,
			'bad "bar" parameter',
		);
		
		like(
			exception { $check->({ foo => {}, bar => [] }) },
			qr/^Reference \{\} did not pass type constraint/,
			'two bad parameters; "foo" throws before "bar" gets a chance',
		);
		
		like(
			exception { $check->({ foo => 3, bar => 42, baz => {} }) },
			qr/^Reference \{\} did not pass type constraint/,
			'bad optional "baz" parameter',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42, xxx => 1 }),
			{ XXX => { xxx => 1 }, foo => 3, bar => 42 },
			'additional parameter',
		);
		
		is_deeply(
			$check->({ foo => 3, bar => 42, xxx => 1, yyy => 2, zzz => 3 }),
			{ XXX => { xxx => 1, yyy => 2, zzz => 3 }, foo => 3, bar => 42 },
			'additional parameters',
		);

		is_deeply(
			$check->({ foo => 3, bar => 42, xxx => 1.1, yyy => 2.2, zzz => 3 }),
			{ XXX => { xxx => 1, yyy => 2, zzz => 3 }, foo => 3, bar => 42 },
			'coercion of additional parameters',
		);

		like(
			exception { $check->({ }) },
			qr/^Missing required parameter: foo/,
			'missing parameter',
		);
	};
}


my $Rounded;

$Rounded = Int->plus_coercions(Num, q{ int($_) });
simple_test(
	"simple test with everything inlineable",
	foo => $Rounded,
	bar => Int,
	baz => Optional[ArrayRef->of($Rounded)],
);

$Rounded = Int->plus_coercions(Num, sub { int($_) });
simple_test(
	"simple test with inlineable types, but non-inlineable coercion",
	foo => $Rounded,
	bar => Int,
	baz => Optional[ArrayRef->of($Rounded)],
);

$Rounded = Int->where(sub { !!1 })->plus_coercions(Num, sub { int($_) });
simple_test(
	"simple test with everything non-inlineable",
	foo => $Rounded,
	bar => Int->where(sub { !!1 }),
	baz => Optional[ArrayRef->of($Rounded)],
);

$Rounded = Int->plus_coercions(Num, q{ int($_) });
slurpy_test(
	"slurpy test with everything inlineable",
	foo => $Rounded,
	bar => Int,
	baz => Optional[ArrayRef->of($Rounded)],
	XXX => slurpy HashRef[$Rounded],
);

$Rounded = Int->plus_coercions(Num, sub { int($_) });
slurpy_test(
	"slurpy test with inlineable types, but non-inlineable coercion",
	foo => $Rounded,
	bar => Int,
	baz => Optional[ArrayRef->of($Rounded)],
	XXX => slurpy HashRef[$Rounded],
);

$Rounded = Int->where(sub { !!1 })->plus_coercions(Num, sub { int($_) });
slurpy_test(
	"slurpy test with everything non-inlineable",
	foo => $Rounded,
	bar => Int->where(sub { !!1 }),
	baz => Optional[ArrayRef->of($Rounded)],
	XXX => slurpy HashRef[$Rounded],
);

subtest "Shortcuts for Any and Optional[Any]" => sub {
	my $chk = compile_named(foo => 1, bar => 0);
	is(
		exception { $chk->(foo => "xyz") },
		undef,
	);
	is(
		exception { $chk->(foo => "xyz", bar => "abc") },
		undef,
	);
	like(
		exception { $chk->(foo => "xyz", bar => "abc", baz => "def") },
		qr/(Unrecognized parameter)|(Wrong number of parameters)/,
	);
	like(
		exception { $chk->(bar => "abc") },
		qr/^Missing required parameter/,
	);
};

done_testing;
