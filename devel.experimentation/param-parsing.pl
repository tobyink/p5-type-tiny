use v5.10;
use strict;
use warnings;

BEGIN {
	package Type::Check;
	no thanks;
	
	use Carp qw(croak);
	use Devel::Caller qw(caller_args);
	use Eval::Closure ();
	use Scope::Upper ();
	use Types::Standard -types;
	use Types::TypeTiny qw(to_TypeTiny);
	
	use Sub::Exporter::Progressive -setup => {
		exports  => ['validate'],
		groups   => {
			default => ['validate'],
		},
	};
	
	sub _mkslurpy
	{
		my ($name, $type, $tc, $i) = @_;
		$type eq '@'
			? sprintf(
				'%s = [ @_[%d..$#_] ];',
				$name,
				$i,
			)
			: sprintf(
				'%s = $#_-%d==0 ? $croaker->("Odd number of elements in %s") : +{ @_[%d..$#_] };',
				$name,
				$i,
				$tc,
				$i,
			);
	}
	
	my %compiled;
	sub validate
	{	
		my @args  = ref($_[0]) eq 'ARRAY'  ? @{+shift} : caller_args(1);
		my $uniq  = join '|', (caller 1)[1..3,8], Scope::Upper::UP();
		
		$compiled{$uniq} ||= do
		{
			my (@code, %env);
			
			@code = 'my (@R, %tmp, $tmp);';
			$env{'$croaker'} = \sub {
				local $Carp::CarpLevel = 4;
				Carp::croak($_[0]);
			};
			
			my $arg = -1;
			
			while (@_)
			{
				++$arg;
				my $constraint = shift;
				my $is_optional;
				my $varname;
				
				if (HashRef->check($constraint))
				{
					$constraint = to_TypeTiny($constraint->{slurpy});
					push @code,
						$constraint->is_a_type_of(HashRef)  ? _mkslurpy('$_', '%', HashRef  => $arg) :
						$constraint->is_a_type_of(Dict)     ? _mkslurpy('$_', '%', Dict     => $arg) :
						$constraint->is_a_type_of(Map)      ? _mkslurpy('$_', '%', Map      => $arg) :
						$constraint->is_a_type_of(ArrayRef) ? _mkslurpy('$_', '@', ArrayRef => $arg) :
						$constraint->is_a_type_of(Tuple)    ? _mkslurpy('$_', '@', Tuple    => $arg) :
						croak("Slurpy parameter not of type HashRef or ArrayRef");
					$varname = '$_';
				}
				else
				{
					$is_optional = grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
					
					if ($is_optional)
					{
						push @code, sprintf 'return @R if $#_ < %d;', $arg;
					}
					
					$varname = sprintf '$_[%d]', $arg;
				}
				
				if ($constraint->has_coercion and $constraint->coercion->can_be_inlined)
				{
					push @code, sprintf(
						'$tmp%s = %s;',
						($is_optional ? '{x}' : ''),
						$constraint->coercion->inline_coercion($varname)
					);
					$varname = '$tmp'.($is_optional ? '{x}' : '');
				}
				elsif ($constraint->has_coercion)
				{
					$env{'@coerce'}[$arg] = $constraint->coercion->compiled_coercion;
					push @code, sprintf(
						'$tmp%s = $coerce[%d]->(%s);',
						($is_optional ? '{x}' : ''),
						$arg,
						$varname,
					);
					$varname = '$tmp'.($is_optional ? '{x}' : '');
				}

				if ($constraint->can_be_inlined)
				{
					push @code, sprintf(
						'(%s) or $croaker->("Value \\"%s\\" in $_[%d] does not meet type constraint \\"%s\\"");',
						$constraint->inline_check($varname),
						$varname,
						$arg,
						$constraint,
					);
				}
				else
				{
					$env{'@check'}[$arg] = $constraint->compiled_check;
					push @code, sprintf(
						'%s or $croaker->("Value \\"%s\\" in $_[%d] does not meet type constraint \\"%s\\"");',
						sprintf(sprintf '$check[%d]->(%s)', $arg, $varname),
						$varname,
						$arg,
						$constraint,
					);
				}
				
				push @code, sprintf 'push @R, %s;', $varname;
			}
			
			push @code, 'return @R;';
			
			my $comment = sprintf('line 0 "parameter validation for %s"', [caller 1]->[3]);
			my $source  = "# $comment\nsub { no warnings; ".join("\n", @code)." };";
			
			Eval::Closure::eval_closure(
				source      => $source,
				environment => \%env,
			);
		};
		
		return $compiled{$uniq}->(@args);
	}	
};

BEGIN {
	$ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS';
};

use Benchmark qw(cmpthese);
use Data::Dumper;
use IO::Handle;
use Params::Validate qw( validate_pos ARRAYREF SCALAR );
use Type::Check validate => { -as => "check" };
use Type::Utils;
use Types::Standard qw( -types slurpy );

sub foo1
{
	state $spec = [
		ArrayRef[Int],
		duck_type(PrintAndSay => ["print", "say"]),
		declare(SmallInt => as Int, where { $_ < 90 }, inline_as { $_[0]->parent->inline_check($_)." and $_ < 90" }),
	];
	my @in = check(@$spec);
}

sub foo2
{
	state $spec = [
		{ type => ARRAYREF, callbacks => { 'all ints' => sub { !grep !/^\d+$/, @{+shift} } } },
		{ can  => ["print", "say"] },
		{ type => SCALAR, regex => qr{^\d+$}, callbacks => { 'less than 90' => sub { shift() < 90 } } },
	];
	my @in = validate_pos(@_, @$spec);
}

our @data = (
	[1, 2, 3],
	IO::Handle->new,
	50,
);

cmpthese(-1, {
	'Type::Check'       => q{ foo1(@::data) },
	'Params::Validate'  => q{ foo2(@::data) },
});
