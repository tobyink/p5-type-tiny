=pod

=encoding utf-8

=head1 PURPOSE

Test C<wrap_subs> and C<wrap_methods> from L<Type::Params>.

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

{
	package Local::Test1;
	use Types::Standard qw( Str Int Num ArrayRef );
	use Type::Params qw( wrap_subs wrap_methods compile_named );
	sub abc {
		return @_;
	}
	sub xyz {
		return @_;
	}
	wrap_subs(
		abc => [Int, Int, Int],
		uvw => [Str],   # wraps sub {}
		xyz => compile_named({ subname => 'xyz' }, x => Int, y => Int, z => Int),
	);
}

subtest "simple use of wrap_subs" => sub {
	is_deeply(
		[ Local::Test1::abc(1, 2, 3) ],
		[ 1, 2, 3 ],
	);
	
	is_deeply(
		[Local::Test1::uvw('hello world')],
		[],
	);
	
	is_deeply(
		[ Local::Test1::xyz(x => 1, y => 2, z => 3) ],
		[{ x => 1, y => 2, z => 3 }],
	);
	
	my $e = exception {
		Local::Test1::abc(1, 2),
	};
	
	like($e, qr/Wrong number of parameters/);
	
	$e = exception {
		Local::Test1::uvw({}),
	};
	
	like($e, qr/Reference \{\} did not pass type constraint "Str" \(in \$_\[0]\)/);
	
	$e = exception {
		Local::Test1::xyz(x => 1, y => 2, z => []),
	};
	
	like($e, qr/Reference \[\] did not pass type constraint "Int" \(in \$_\{"z"\}\)/);
};

{
	package Local::Test2;
	use Types::Standard qw( Str Int Num ArrayRef );
	use Type::Params qw( wrap_subs wrap_methods compile_named );
	sub abc {
		return @_;
	}
	sub def {
		return @_;
	}
	sub xyz {
		return @_;
	}
	wrap_methods(
		abc => [Int, Int, Int],
		uvw => [Str],   # wraps sub {}
		xyz => compile_named({ subname => 'xyz' }, x => Int, y => Int, z => Int),
	);
}

subtest "simple use of wrap_methods" => sub {
	is_deeply(
		[ Local::Test2->abc(1, 2, 3) ],
		[ 'Local::Test2', 1, 2, 3 ],
	);
	
	is_deeply(
		[ Local::Test2->uvw('hello world') ],
		[],
	);
	
	is_deeply(
		[ Local::Test2->xyz(x => 1, y => 2, z => 3) ],
		[ 'Local::Test2', { x => 1, y => 2, z => 3 }],
	);
	
	my $e = exception {
		Local::Test2->abc(1, 2),
	};
	
	like($e, qr/Wrong number of parameters/);
	
	$e = exception {
		Local::Test2->uvw({}),
	};
	
	like($e, qr/Reference \{\} did not pass type constraint "Str" \(in \$_\[1]\)/);
	
	$e = exception {
		Local::Test2->xyz(x => 1, y => 2, z => []),
	};
	
	like($e, qr/Reference \[\] did not pass type constraint "Int" \(in \$_\{"z"\}\)/);
};

{
	package Local::Test3;
	our @ISA = 'Local::Test2';
	use Types::Standard qw( Str Int Num ArrayRef );
	use Type::Params qw( wrap_subs wrap_methods compile_named );
	my $Even = Int->where(q{ $_ % 2 == 0 });
	wrap_methods(
		abc => [$Even, $Even, $Even],
		def => [Num],   # inherited
	);
}

subtest "wrap_methods with inheritance" => sub {
	is_deeply(
		[ Local::Test3->abc(2, 4, 6) ],
		[ 'Local::Test3', 2, 4, 6 ],
	);
	
	is_deeply(
		[ Local::Test3->def(3.1) ],
		[ 'Local::Test3', 3.1 ],
	);
	
	is_deeply(
		[ Local::Test3->uvw('hello world') ],
		[],
	);
	
	is_deeply(
		[ Local::Test3->xyz(x => 1, y => 2, z => 3) ],
		[ 'Local::Test3', { x => 1, y => 2, z => 3 }],
	);
	
	my $e = exception {
		Local::Test3->abc(1, 2, 2),
	};
	
	like($e, qr/Value "1" did not pass type constraint \(in \$_\[1\]\)/);
	
	$e = exception {
		Local::Test3->def({}),
	};
	
	like($e, qr/Reference \{\} did not pass type constraint "Num" \(in \$_\[1]\)/);
	
	$e = exception {
		Local::Test3->uvw({}),
	};
	
	like($e, qr/Reference \{\} did not pass type constraint "Str" \(in \$_\[1]\)/);
	
	$e = exception {
		Local::Test3->xyz(x => 1, y => 2, z => []),
	};
	
	like($e, qr/Reference \[\] did not pass type constraint "Int" \(in \$_\{"z"\}\)/);
};

done_testing;
