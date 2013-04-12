use strict;
use warnings;

BEGIN {
	package Type::Check;
	no thanks;
	
	use Carp qw(croak);
	use Devel::Caller qw(caller_args);
	use Types::Standard -types;
	use Types::TypeTiny qw(to_TypeTiny);
	
	use base "Exporter";
	our @EXPORT = qw( check );
	our @EXPORT_OK = qw( _check );
	
	sub check
	{
		my @args      = ArrayRef->check($_[0])  ? @{+shift} : caller_args(1);
		my $carplevel = ScalarRef->check($_[0]) ? ${+shift} : 1;
		my @return;
		
		my $signature = join ", ", map { ref($_) eq 'HASH' ? "slurpy $_->{slurpy}" : "$_" } @_;

		local $Carp::Internal{+__PACKAGE__} = 1;

		while (@_)
		{
			my $constraint = shift;
			
			if (HashRef->check($constraint))
			{
				$constraint = to_TypeTiny($constraint->{slurpy});
				my $arg =
					$constraint->is_a_type_of(HashRef)  ? +{@args % 2 ? croak("Odd number of elements for slurpy $constraint") : @args } :
					$constraint->is_a_type_of(Dict)     ? +{@args % 2 ? croak("Odd number of elements for slurpy $constraint") : @args } :
					$constraint->is_a_type_of(Map)      ? +{@args % 2 ? croak("Odd number of elements for slurpy $constraint") : @args } :
					$constraint->is_a_type_of(ArrayRef) ? +[@args] :
					$constraint->is_a_type_of(Tuple)    ? +[@args] :
					croak("Slurpy parameter not of type HashRef or ArrayRef");
				
				local $Carp::CarpLevel = $carplevel + 2;
				push @return,
					$constraint->has_coercion       ? $constraint->assert_coerce($arg) :
					$constraint->assert_valid($arg) ? $arg : undef;
				@args = ();
				next;
			}
			
			$constraint = to_TypeTiny($constraint);
			my $is_optional = grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
			
			if (not @args)
			{
				if (not $is_optional)
				{
					local $Carp::CarpLevel = $carplevel + 1;
					croak("Wrong number of arguments (sub signature: $signature)");
					next;  # never happens??
				}
				return @return;
			}
			
			my @arg = @args ? shift(@args) : ();
			
			local $Carp::CarpLevel = 3;
			push @return,
				$constraint->has_coercion       ? $constraint->assert_coerce(@arg) :
				$constraint->assert_valid(@arg) ? $arg[0] : undef;
		}
		
		return (@return, @args);
	}
	
	*_check = \&check;
};

use Data::Dumper;
use Type::Check qw( _check );
use Type::Utils;
use Types::Standard qw( -types slurpy );

my $RoundedInt = declare RoundedInt => as Int;
coerce $RoundedInt, from Num, q{ int($_) };

sub foo {
	my ($name, $age, $bits) = _check(Str, $RoundedInt, slurpy HashRef[Int]);
	
	print Dumper {
		name  => $name,
		age   => $age,
		bits  => $bits,
	};
}

sub bar {
	foo("Bob", 32.5, foo => 1);
}

bar();
