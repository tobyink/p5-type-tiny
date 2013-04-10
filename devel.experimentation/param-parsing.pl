BEGIN {
	package Type::Checked;
	no thanks;
	
	use strict;
	use warnings;
	
	use Carp qw(croak);
	use Devel::Caller qw(caller_args);
	use Types::Standard -types;
	
	use base "Exporter";
	our @EXPORT = qw( check );
	
	sub check
	{
		my @args = ref $_[0] eq "ARRAY" ? @{+shift} : caller_args(1);
		my @return;
				
		while (@_)
		{
			my $constraint = shift;
			
			if (ref $constraint eq 'HASH')
			{
				$constraint = $constraint->{slurpy};
				my $arg =
					$constraint->is_a_type_of(HashRef)  ? +{@args % 2 ? croak("Odd number of elements in slurpy $constraint") : @args } :
					$constraint->is_a_type_of(Dict)     ? +{@args % 2 ? croak("Odd number of elements in slurpy $constraint") : @args } :
					$constraint->is_a_type_of(Map)      ? +{@args % 2 ? croak("Odd number of elements in slurpy $constraint") : @args } :
					$constraint->is_a_type_of(ArrayRef) ? +[@args] :
					$constraint->is_a_type_of(Tuple)    ? +[@args] :
					croak("Slurpy parameter not of type HashRef or ArrayRef");
				
				local $Carp::CarpLevel = 3;
				push @return,
					$constraint->has_coercion       ? $constraint->assert_coerce($arg) :
					$constraint->assert_valid($arg) ? $arg : undef;
				@args = ();
			}
			else
			{
				my @arg = @args ? shift(@args) : ();
				
				@arg or $constraint =~ /^Optional\b/ or croak("Wrong number of arguments");
				
				local $Carp::CarpLevel = 3;
				push @return,
					$constraint->has_coercion       ? $constraint->assert_coerce(@arg) :
					$constraint->assert_valid(@arg) ? $arg[0] : undef;
			}
		}
		
		return (@return, @args);
	}
};

use Data::Dumper;
use Type::Checked;
use Type::Utils;
use Types::Standard qw( -types slurpy );

my $RoundedInt = declare RoundedInt, as Int;
coerce $RoundedInt, from Num, q{ int($_) };

sub foo {
	my ($name, $age, $bits) = check(\@_, Str, $RoundedInt, slurpy HashRef[Int]);
	
	print Dumper {
		name  => $name,
		age   => $age,
		bits  => $bits,
	};
}

sub bar {
	foo("Bob", 32.5, foo=>1);
}

bar();
