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

# Now we'll just do a simple check of argument count; not checking any types!
print "\n----\n\n";
our $CHK  = compile(1, 1, 0);
our @ARGS = 1..2;
cmpthese(-3, {
	TypeParamsSimple     => q { $::CHK->(@::ARGS) },
	ParamsValidateSimple => q { validate_pos(@::ARGS, 1, 1, 0) },
});

__END__
           Rate   [D:V]   [P:V] [T:P v]   [P:C] [T:P c]
[D:V]   10006/s      --    -26%    -38%    -39%    -68%
[P:V]   13567/s     36%      --    -15%    -17%    -57%
[T:P v] 16012/s     60%     18%      --     -2%    -49%
[P:C]   16384/s     64%     21%      2%      --    -48%
[T:P c] 31220/s    212%    130%     95%     91%      --

----

                         Rate ParamsValidateSimple     TypeParamsSimple
ParamsValidateSimple  91317/s                   --                 -60%
TypeParamsSimple     229049/s                 151%                   --
