use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Benchmark;
use Benchmark qw(timethis);

$Test::Benchmark::VERBOSE = 1;

{
	package UseSV;
	
	use Scalar::Validation qw(:all);
	
	sub test {
		my $p_bool = par p_bool => -Enum => [0 => '1']               => shift;
		my $p_123  = par p_123  => -Enum => {1 => 1, 2 => 1, 3 => 1} => shift;
		my $p_free = par p_free => sub { $_ > 5 } => shift, sub { "$_ is not larger than 5" };
		p_end \@_;
		
		return $p_bool + $p_123 + $p_free;
	}
}

{
	package UseTP;
	
	use Type::Params qw(compile);
	use Types::Standard qw(Enum);
	use Types::XSD::Lite qw(Integer);
	
	my $_check = compile Enum[0,1], Enum[1..3], Integer[minExclusive => 5];
	
	sub test {
		my ($p_bool, $p_123, $p_free) = $_check->(@_);
		return $p_bool + $p_123 + $p_free;
	}
}

subtest "Scalar::Validation works ok" => sub {
	is( UseSV::test(1,2,7), 10 );
	
	like(
		exception { UseSV::test(2,2,2) },
		qr/^Error/,
	);
};

subtest "Type::Params works ok" => sub {
	is( UseTP::test(1,2,7), 10 );
	
	like(
		exception { UseTP::test(2,2,2) },
		qr/did not pass type constraint/,
	);
};

is_fastest('TP', -1, {
	SV  => q[ UseSV::test(1,2,7) ],
	TP  => q[ UseTP::test(1,2,7) ],
}, 'Type::Params is fastest at passing validations');

is_fastest('TP', -1, {
	SV  => q[ eval { UseSV::test(1,2,3) } ],
	TP  => q[ eval { UseTP::test(1,2,3) } ],
}, 'Type::Params is fastest at failing validations');

done_testing;

__END__
	# Subtest: Scalar::Validation works ok
	ok 1
	ok 2
	1..2
ok 1 - Scalar::Validation works ok
	# Subtest: Type::Params works ok
	ok 1
	ok 2
	1..2
ok 2 - Type::Params works ok
ok 3 - Type::Params is fastest at passing validations
# TP -  2 wallclock secs ( 1.17 usr +  0.00 sys =  1.17 CPU) @ 6564.10/s (n=7680)
# SV -  1 wallclock secs ( 1.03 usr +  0.00 sys =  1.03 CPU) @ 4744.66/s (n=4887)
ok 4 - Type::Params is fastest at failing validations
# TP -  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 3412.38/s (n=3583)
# SV -  1 wallclock secs ( 1.07 usr +  0.03 sys =  1.10 CPU) @ 1285.45/s (n=1414)
1..4
