=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with slurpy parameters.

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

use Type::Params qw( compile signature );
use Types::Standard -types, "slurpy";

my $chk = compile(Str, slurpy HashRef[Int]);

is_deeply(
	[ $chk->("Hello", foo => 1, bar => 2) ],
	[ "Hello", { foo => 1, bar => 2 } ],
	'simple test',
);

is_deeply(
	[ $chk->("Hello", { foo => 1, bar => 2 }) ],
	[ "Hello", { foo => 1, bar => 2 } ],
	'simple test with ref',
);

like(
	exception { $chk->("Hello", foo => 1, bar => 2.1) },
	qr{did not pass type constraint "HashRef\[Int\]" \(in \$SLURPY\)},
	'simple test failing type check',
);

subtest "Different styles of slurpy work" => sub {
	for my $compile_this (
		[ 'Str, slurpy HashRef'           => Str, slurpy HashRef ],
		[ 'Str, Slurpy[HashRef]'          => Str, Slurpy[HashRef] ],
		[ 'Str, HashRef, { slurpy => 1 }' => Str, HashRef, { slurpy => 1 } ],
		[ 'Str, { slurpy => HashRef }'    => Str, { 'slurpy' => HashRef } ],
	) {
		my ( $desc, @args ) = @$compile_this;
		subtest "Compiling: $desc" => sub {
			my $chk2 = compile @args;

			is_deeply(
				[ $chk2->("Hello", foo => 1, bar => 2) ],
				[ "Hello", { foo => 1, bar => 2 } ]
			);

			is_deeply(
				[ $chk2->("Hello", { foo => 1, bar => 2 }) ],
				[ "Hello", { foo => 1, bar => 2 } ]
			);

			like(
				exception { $chk2->("Hello", foo => 1, "bar") },
				qr{^Odd number of elements in HashRef},
			);
		};
	}
};

subtest "slurpy Map works" => sub {
	my $chk3 = compile(Str, slurpy Map);
	
	is_deeply(
		[ $chk3->("Hello", foo => 1, "bar" => 2) ],
		[ Hello => { foo => 1, bar => 2 } ],
	);
	
	like(
		exception { $chk3->("Hello", foo => 1, "bar") },
		qr{^Odd number of elements in Map},
	);
};

subtest "slurpy Tuple works" => sub {
	my $chk4 = compile(Str, slurpy Tuple[Str, Int, Str]);
	
	is_deeply(
		[ $chk4->("Hello", foo => 1, "bar") ],
		[ Hello => [ qw/ foo 1 bar / ] ],
	);
};

{
	my $check;
	sub xyz {
		$check ||= compile( Int, Slurpy[HashRef] );
		my ($num, $hr) = $check->(@_);
		return [ $num, $hr ];
	}
	
	subtest "Slurpy[HashRef] works" => sub {
		is_deeply( xyz( 5,   foo => 1, bar => 2   ), [ 5, { foo => 1, bar => 2 } ] );
		is_deeply( xyz( 5, { foo => 1, bar => 2 } ), [ 5, { foo => 1, bar => 2 } ] );
		
		note compile( { want_source => 1 }, Int, Slurpy[HashRef] );
	};
}

{
	my $check;
	sub xyz2 {
		$check ||= compile( Int, HashRef, { slurpy => 1 } );
		my ($num, $hr) = $check->(@_);
		return [ $num, $hr ];
	}
	
	subtest "HashRef { slurpy => 1 } works" => sub {
		is_deeply( xyz2( 5,   foo => 1, bar => 2   ), [ 5, { foo => 1, bar => 2 } ] );
		is_deeply( xyz2( 5, { foo => 1, bar => 2 } ), [ 5, { foo => 1, bar => 2 } ] );
	};
}

{
	my $check;
	sub xyz3 {
		$check ||= compile( Int, { slurpy => HashRef } );
		my ($num, $hr) = $check->(@_);
		return [ $num, $hr ];
	}
	
	subtest "{ slurpy => HashRef } works" => sub {
		is_deeply( xyz3( 5,   foo => 1, bar => 2   ), [ 5, { foo => 1, bar => 2 } ] );
		is_deeply( xyz3( 5, { foo => 1, bar => 2 } ), [ 5, { foo => 1, bar => 2 } ] );
	};
}

{
	my $check;
	sub xyz4 {
		$check ||= compile( Int, ( Slurpy[HashRef] )->where( '1' ) );
		my ($num, $hr) = $check->(@_);
		return [ $num, $hr ];
	}
	
	subtest "Subtype of Slurpy[HashRef] works" => sub {
		is_deeply( xyz4( 5,   foo => 1, bar => 2   ), [ 5, { foo => 1, bar => 2 } ] );
		is_deeply( xyz4( 5, { foo => 1, bar => 2 } ), [ 5, { foo => 1, bar => 2 } ] );
		
		note compile( { want_source => 1 }, Int, ( Slurpy[HashRef] )->where( '1' ) );
	};
}

{
	my $e = exception {
		signature(
			positional => [ Slurpy[ArrayRef], ArrayRef ],
		);
	};
	like(
		$e,
		qr/Parameter following slurpy parameter/,
		'Exception thrown for parameter after a slurpy in positional signature',
	);
}

{
	my $e = exception {
		signature(
			positional => [ Slurpy[ArrayRef], Slurpy[ArrayRef] ],
		);
	};
	like(
		$e,
		qr/Parameter following slurpy parameter/,
		'Exception thrown for slurpy parameter after a slurpy in positional signature',
	);
}

{
	my $e = exception {
		signature(
			named => [ foo => Slurpy[ArrayRef], bar => Slurpy[ArrayRef] ],
		);
	};
	like(
		$e,
		qr/Found multiple slurpy parameters/i,
		'Exception thrown for named signature with two slurpies',
	);
}

{
	my $e = exception {
		signature(
			named => [ foo => Slurpy[ArrayRef] ],
		);
	};
	like(
		$e,
		qr/Signatures with named parameters can only have slurpy parameters which are a subtype of HashRef/i,
		'Exception thrown for named signature with ArrayRef slurpy',
	);
}

{
	my $check;
	my $e = exception {
		$check = signature(
			named => [ bar => Slurpy[HashRef], foo => ArrayRef ],
			bless => 0,
		);
	};
	is(
		$e,
		undef,
		'Named signature may have slurpy parameter before others',
	);
	is_deeply(
		[ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ],
		[ { foo => [ 1..4 ], bar => { abc => 1, def => 2 } } ],
		'... and expected behaviour',
	) or diag explain [ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ];
}

{
	my $check;
	my $e = exception {
		$check = signature(
			named => [ bar => Slurpy[HashRef], foo => ArrayRef ],
			named_to_list => 1,
		);
	};
	is(
		$e,
		undef,
		'Named-to-list => 1 signature may have slurpy parameter before others',
	);
	is_deeply(
		[ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ],
		[ { abc => 1, def => 2 }, [ 1..4 ] ],
		'... and expected behaviour',
	) or diag explain [ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ];
}

{
	my $check;
	my $e = exception {
		$check = signature(
			named => [ bar => Slurpy[HashRef], foo => ArrayRef ],
			named_to_list => [ qw( foo bar ) ],
		);
	};
	is(
		$e,
		undef,
		'Named-to-list => ARRAY signature may have slurpy parameter before others',
	);
	is_deeply(
		[ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ],
		[ [ 1..4 ], { abc => 1, def => 2 } ],
		'... and expected behaviour',
	) or diag explain [ $check->( foo => [ 1..4 ], abc => 1, def => 2 ) ];
}

done_testing;

