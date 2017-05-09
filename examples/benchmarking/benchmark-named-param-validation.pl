=pod

=encoding utf-8

=head1 TEST 1: COMPLEX PARAMETER CHECKING

Compares the run-time speed of several parameter validators for validating
a fairly complex function signature. The function accepts an arrayref,
an object providing C<print> and C<say> methods, and an integer less than
90 as named parameters (C<a>, C<o>, and C<i>).

The validators tested were:

=over

=item B<Params::ValidationCompiler> (shown as B<< PVC m|s|t >> in the results table)

L<Params::ValidationCompiler> with Moose, Specio, and Type::Tiny type
constraints.

=item B<Data::Validator> (shown as B<D:V> in results table)

=item B<Params::Validate> (shown as B<P:V> in results table)

C<validate> given the following spec:

   state $spec = {
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
   };

=item B<Params::Check> (shown as B<P:C> in results table)

Given three coderefs to validate parameters.

=item B<< Type::Params::validate_named() >> (shown as B<< T:P v >> in results table)

Called as:

   validate_named(\@_, a=>ArrayRef, o=>$PrintAndSay, i=>$SmallInt);

Where C<< $PrintAndSay >> is a duck type, and C<< $SmallInt >> is a
subtype of C<< Int >>, with inlining defined.

=item B<< Type::Params::compile_named() >> (shown as B<< T:P c >> in results table)

Using the same type constraints as C<< validate_named() >>

=back

=head2 Results

B<< With Type::Tiny::XS: >>

             Rate  [P:C] [P:V] [T:P v] [D:V] [PVC m] [PVC s] [PVC t] [T:P c]
 [P:C]    46987/s     --  -28%    -49%  -55%    -59%    -60%    -73%    -79%
 [P:V]    65535/s    39%    --    -28%  -37%    -43%    -44%    -62%    -71%
 [T:P v]  91413/s    95%   39%      --  -12%    -21%    -22%    -47%    -59%
 [D:V]   103722/s   121%   58%     13%    --    -10%    -11%    -40%    -54%
 [PVC m] 115369/s   146%   76%     26%   11%      --     -1%    -33%    -49%
 [PVC s] 117055/s   149%   79%     28%   13%      1%      --    -32%    -48%
 [PVC t] 173062/s   268%  164%     89%   67%     50%     48%      --    -23%
 [T:P c] 225563/s   380%  244%    147%  117%     96%     93%     30%      --

B<< Without Type::Tiny::XS: >>

             Rate  [P:C] [D:V] [P:V] [T:P v] [PVC s] [PVC m] [PVC t] [T:P c]
 [P:C]    47135/s     --  -24%  -29%    -41%    -59%    -59%    -67%    -73%
 [D:V]    61637/s    31%    --   -7%    -23%    -47%    -47%    -56%    -65%
 [P:V]    66354/s    41%    8%    --    -17%    -43%    -43%    -53%    -62%
 [T:P v]  79712/s    69%   29%   20%      --    -31%    -31%    -44%    -54%
 [PVC s] 115564/s   145%   87%   74%     45%      --     -0%    -18%    -34%
 [PVC m] 115967/s   146%   88%   75%     45%      0%      --    -18%    -34%
 [PVC t] 141276/s   200%  129%  113%     77%     22%     22%      --    -19%
 [T:P c] 174687/s   271%  183%  163%    119%     51%     51%     24%      --

(Tested versions: Data::Validator 1.07 with Mouse 2.4.7,
Params::ValidationCompiler 0.23 with Moose 2.2002 and Specio 0.34
Params::Validate 1.26, Params::Check 0.38, and Type::Params 1.001_007
with Type::Tiny::XS 0.012.)

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) provides the fastest way of
checking named parameters for a function, whether or not Type::Tiny::XS
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

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use feature qw(state);
use Benchmark qw(cmpthese);

# In today's contest, we'll be comparing Type::Params...
#
use Type::Params qw( compile_named validate_named );
use Type::Utils;
use Types::Standard qw( -types );

# ... with Params::Validate...
#
BEGIN { $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS' }; # ... which we'll give a fighting chance
use Params::Validate qw( validate ARRAYREF SCALAR );

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
	my @in = validate_named(\@_, a => ArrayRef, o => $PrintAndSay, i => $SmallInt);
}

sub TypeParams_compile
{
	state $spec = compile_named(a => ArrayRef, o => $PrintAndSay, i => $SmallInt);
	my @in = $spec->(@_);
}

sub ParamsValidate
{
	state $spec = {
		a => { type => ARRAYREF },
		o => { can  => ["print", "say"] },
		i => { type => SCALAR, regex => qr{^\d+$}, callbacks => { 'less than 90' => sub { shift() < 90 } } },
	};
	my @in = validate(@_, $spec);
}

sub ParamsValidationCompiler_moose
{
	state $check = Params::ValidationCompiler::validation_for(
		params => {
			a => { type => Moose::Util::TypeConstraints::find_type_constraint('ArrayRef') },
			o => { type => Moose::Util::TypeConstraints::duck_type([qw/print say/]) },
			i => { type => $SmallIntMoose },
		},
	);
	my @in = $check->(@_);
}

sub ParamsValidationCompiler_tt
{
	state $check = Params::ValidationCompiler::validation_for(
		params => {
			a => { type => ArrayRef },
			o => { type => $PrintAndSay },
			i => { type => $SmallInt },
		},
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
			params => {
				a => { type => t('ArrayRef') },
				o => { type => $duck },
				i => { type => $smint },
			},
		);
		my @in = $check->(@_);
	}
}

sub ParamsCheck
{
	state $spec = {
		a => { required => 1, allow => sub { ref $_[0] eq 'ARRAY' }},
		o => { required => 1, allow => sub { Scalar::Util::blessed($_[0]) and $_[0]->can("print") and $_[0]->can("say") }},
		i => { required => 1, allow => sub  { !ref($_[0]) and $_[0] =~ m{^\d+$} and $_[0] < 90 }},
	};
	my @in = Params::Check::check($spec, {@_});
}

sub DataValidator
{
	state $spec = "Data::Validator"->new(
		a => "ArrayRef",
		o => $PrintAndSay2,
		i => $SmallInt2,
	);
	my @in = $spec->validate(@_);
}

# Actually run the benchmarks...
#

use IO::Handle ();
our @data = (
	a => [1, 2, 3],
	o => IO::Handle->new,
	i => 50,
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

