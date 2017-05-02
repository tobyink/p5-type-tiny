=pod

=encoding utf-8

=head1 TEST 1: COMPLEX PARAMETER CHECKING

Compares the run-time speed of several parameter validators for validating
a fairly complex function signature. The function accepts an arrayref,
followed by an object providing C<print> and C<say> methods, followed
by an integer less than 90.

The validators tested were:

=over

=item B<Params::ValidationCompiler> (shown as B<< PVC m|s|t >> in the results table)

L<Params::ValidationCompiler> with Moose, Specio, and Type::Tiny type
constraints.

=item B<Data::Validator> (shown as B<D:V> in results table)

Using the C<StrictSequenced> trait.

=item B<Params::Validate> (shown as B<P:V> in results table)

C<validate_pos> given the following spec:

   state $spec = [
      {  type      => ARRAYREF,
      },
      {  can       => ["print", "say"],
      },
      {  type      => SCALAR,
         regex     => qr{^\d+$},
         callbacks => {
            'less than 90' => sub { shift() < 90 },
         },
      },
   ];

=item B<Params::Check> (shown as B<P:C> in results table)

Given three coderefs to validate parameters.

=item B<< Type::Params::validate() >> (shown as B<< T:P v >> in results table)

Called as:

   validate(\@_, ArrayRef, $PrintAndSay, $SmallInt);

Where C<< $PrintAndSay >> is a duck type, and C<< $SmallInt >> is a
subtype of C<< Int >>, with inlining defined.

=item B<< Type::Params::compile() >> (shown as B<< T:P c >> in results table)

Using the same type constraints as C<< validate() >>

=back

=head2 Results

B<< With Type::Tiny::XS: >>

             Rate  [P:V] [D:V] [P:C] [T:P v] [PVC s] [PVC m] [PVC t] [T:P c]
 [P:V]    65659/s     --  -14%  -49%    -49%    -57%    -57%    -82%    -83%
 [D:V]    76554/s    17%    --  -40%    -41%    -50%    -50%    -78%    -80%
 [P:C]   128061/s    95%   67%    --     -1%    -16%    -16%    -64%    -67%
 [T:P v] 129505/s    97%   69%    1%      --    -15%    -15%    -64%    -66%
 [PVC s] 152800/s   133%  100%   19%     18%      --     -0%    -57%    -60%
 [PVC m] 153111/s   133%  100%   20%     18%      0%      --    -57%    -60%
 [PVC t] 355400/s   441%  364%  178%    174%    133%    132%      --     -7%
 [T:P c] 382293/s   482%  399%  199%    195%    150%    150%      8%      --

B<< Without Type::Tiny::XS: >>

             Rate  [D:V] [P:V] [T:P v] [P:C] [PVC s] [PVC m] [PVC t] [T:P c]
 [D:V]    40714/s     --  -52%    -59%  -66%    -73%    -79%    -80%    -81%
 [P:V]    85423/s   110%    --    -15%  -28%    -43%    -56%    -59%    -61%
 [T:P v] 100161/s   146%   17%      --  -16%    -33%    -49%    -52%    -54%
 [P:C]   118634/s   191%   39%     18%    --    -21%    -39%    -43%    -46%
 [PVC s] 150390/s   269%   76%     50%   27%      --    -23%    -28%    -31%
 [PVC m] 194626/s   378%  128%     94%   64%     29%      --     -7%    -11%
 [PVC t] 208762/s   413%  144%    108%   76%     39%      7%      --     -4%
 [T:P c] 217803/s   435%  155%    117%   84%     45%     12%      4%      --

(Tested versions: Data::Validator 1.07 with Mouse 2.4.7,
Params::ValidationCompiler 0.23 with Moose 2.2002 and Specio 0.34
Params::Validate 1.26, Params::Check 0.38, and Type::Params 1.001_007
with Type::Tiny::XS 0.012.)

=head1 TEST B: SIMPLE PARAMETER CHECKING

Based on the idea that I was playing to Type::Params' strengths,
I decided on something I thought would be more of a challenge: a simpler
function signature which takes two required and one optional parameters.
This is purely a test of parameter count; no type checking is involved!

This is a face off between Type::Params and Params::Validate.

=head2 Results

Because no type checks are involved, it doesn't matter whether
Type::Tiny::XS is available or not. (The results are similar either
way.)

              Rate   [P:V] [T:P c]
 [P:V]    300784/s      --    -74%
 [T:P c] 1155745/s    284%      --

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) provides the fastest way of
checking positional parameters for a function, whether or not Type::Tiny::XS
is available.

Params::ValidationCompiler (also using Type::Tiny type constraints) is very
nearly as fast.

Params::ValidationCompiler using other type constraints is also quite fast,
and when Type::Tiny::XS is not available, Moose and Specio constraints run
almost as fast as Type::Tiny constraints.

=head1 DEPENDENCIES

To run this script, you will need:

L<Type::Tiny::XS>,
L<Data::Validator>, L<Mouse>, L<Params::Check>, L<Params::Validate>,
L<Params::ValidationCompiler>, L<Specio>, L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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

# ... and Params::ValidationCompiler
use Moose::Util::TypeConstraints ();
use Specio::Declare ();
BEGIN {
	Specio::Helpers::install_t_sub(
		__PACKAGE__,
		Specio::Registry::internal_types_for_package(__PACKAGE__)
	);
}
use Specio::Library::Builtins;
use Params::ValidationCompiler ();

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

# ... and Moose...
my $SmallIntMoose = Moose::Util::TypeConstraints::subtype(
	"SmallIntMoose",
	Moose::Util::TypeConstraints::as("Int"),
	Moose::Util::TypeConstraints::where(sub { $_ < 90 }),
	Moose::Util::TypeConstraints::inline_as(sub { $_[0]->parent->_inline_check($_[1])." and ${\ $_[1]} < 90" }),
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

sub ParamsValidationCompiler_moose
{
	state $check = Params::ValidationCompiler::validation_for(
		params => [
			{ type => Moose::Util::TypeConstraints::find_type_constraint('ArrayRef') },
			{ type => Moose::Util::TypeConstraints::duck_type([qw/print say/]) },
			{ type => $SmallIntMoose },
		],
	);
	my @in = $check->(@_);
}

sub ParamsValidationCompiler_tt
{
	state $check = Params::ValidationCompiler::validation_for(
		params => [
			{ type => ArrayRef },
			{ type => $PrintAndSay },
			{ type => $SmallInt },
		],
	);
	my @in = $check->(@_);
}

{
	my $duck  = Specio::Declare::object_can_type('PrintAndSay', methods => [qw/print say/]);
	my $smint = Specio::Declare::declare('SmallInt', parent => t('Int'), inline => sub {
		my ($type, $var) = @_;
		$type->parent->inline_check($var)." and $var < 90";
	});	
	sub ParamsValidationCompiler_specio
	{
		state $check = Params::ValidationCompiler::validation_for(
			params => [
				{ type => t('ArrayRef') },
				{ type => $duck },
				{ type => $smint },
			],
		);
		my @in = $check->(@_);
	}
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
	'[PVC m]'  => q{ ParamsValidationCompiler_moose(@::data) },
	'[PVC t]'  => q{ ParamsValidationCompiler_tt(@::data) },
	'[PVC s]'  => q{ ParamsValidationCompiler_specio(@::data) },
});

# Now we'll just do a simple check of argument count; not checking any types!
print "\n----\n\n";
our $CHK  = compile(1, 1, 0);
our @ARGS = 1..2;
cmpthese(-3, {
	'[T:P c]'  => q { $::CHK->(@::ARGS) },
	'[P:V]'    => q { validate_pos(@::ARGS, 1, 1, 0) },
});

