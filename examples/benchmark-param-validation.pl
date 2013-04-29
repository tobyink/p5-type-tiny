use strict;
use warnings;
use feature qw(state);
use Benchmark qw(cmpthese);

# In today's contest, we'll be comparing Type::Params...
#
use Type::Params qw( compile validate );
use Type::Utils;
use Types::Standard qw( -types );

# ... with Params::Validate...
#
BEGIN { $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS' }; # ... which we'll give a fighting chance
use Params::Validate qw( validate_pos ARRAYREF SCALAR );

# ... and Data::Validator...
use Data::Validator ();
use Mouse::Util::TypeConstraints ();

# ... and Params::Check...
use Params::Check ();

# Define custom type constraints...
my $PrintAndSay = duck_type PrintAndSay => ["print", "say"];
my $SmallInt    = declare SmallInt => as Int,
	where     { $_ < 90 },
	inline_as { $_[0]->parent->inline_check($_)." and $_ < 90" };

# ... and for Mouse...
my $PrintAndSay2 = Mouse::Util::TypeConstraints::duck_type(PrintAndSay => ["print", "say"]);
my $SmallInt2 = Mouse::Util::TypeConstraints::subtype(
	"SmallInt",
	Mouse::Util::TypeConstraints::as("Int"),
	Mouse::Util::TypeConstraints::where(sub { $_ < 90 }),
);

sub TypeParams_validate
{
	my @in = validate(\@_, ArrayRef, $PrintAndSay, $SmallInt);
}

sub TypeParams_compile
{
	state $spec = compile(ArrayRef, $PrintAndSay, $SmallInt);
	my @in = $spec->(@_);
}

sub ParamsValidate
{
	state $spec = [
		{ type => ARRAYREF },
		{ can  => ["print", "say"] },
		{ type => SCALAR, regex => qr{^\d+$}, callbacks => { 'less than 90' => sub { shift() < 90 } } },
	];
	my @in = validate_pos(@_, @$spec);
}

sub ParamsCheck
{
	state $spec = [
		[sub { ref $_[0] eq 'ARRAY' }],
		[sub { Scalar::Util::blessed($_[0]) and $_[0]->can("print") and $_[0]->can("say") }],
		[sub { !ref($_[0]) and $_[0] =~ m{^\d+$} and $_[0] < 90 }],
	];
	# Params::Check::check doesn't support positional parameters.
	# Params::Check::allow fakery instead.
	my @in = map {
		Params::Check::allow($_[$_], $spec->[$_])
			? $_[$_]
			: die
	} 0..$#$spec;
}

sub DataValidator
{
	state $spec = "Data::Validator"->new(
		first  => "ArrayRef",
		second => $PrintAndSay2,
		third  => $SmallInt2,
	)->with("StrictSequenced");
	my @in = $spec->validate(@_);
}

# Actually run the benchmarks...
#

use IO::Handle ();
our @data = (
	[1, 2, 3],
	IO::Handle->new,
	50,
);

cmpthese(-3, {
	'[D:V]'    => q{ DataValidator(@::data) },
	'[P:V]'    => q{ ParamsValidate(@::data) },
	'[P:C]'    => q{ ParamsCheck(@::data) },
	'[T:P v]'  => q{ TypeParams_validate(@::data) },
	'[T:P c]'  => q{ TypeParams_compile(@::data) },
});

__END__
           Rate   [D:V]   [P:V]   [P:C] [T:P v] [T:P c]
[D:V]   10114/s      --    -16%    -38%    -47%    -71%
[P:V]   12027/s     19%      --    -27%    -37%    -66%
[P:C]   16432/s     62%     37%      --    -14%    -54%
[T:P v] 19123/s     89%     59%     16%      --    -46%
[T:P c] 35430/s    250%    195%    116%     85%      --
