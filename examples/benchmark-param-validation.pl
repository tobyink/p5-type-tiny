=pod

=encoding utf-8

=head1 TEST 1: COMPLEX PARAMETER CHECKING

Compares the run-time speed of five parameter validators for validating
a fairly complex function signature. The function accepts an arrayref,
followed by an object providing C<print> and C<say> methods, followed
by an integer less than 90.

The validators tested were:

=over

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

            Rate   [D:V]   [P:V]   [P:C] [T:P v] [T:P c]
 [D:V]   10324/s      --     -8%    -35%    -48%    -81%
 [P:V]   11247/s      9%      --    -29%    -43%    -80%
 [P:C]   15941/s     54%     42%      --    -19%    -71%
 [T:P v] 19685/s     91%     75%     23%      --    -64%
 [T:P c] 55304/s    436%    392%    247%    181%      --

B<< Without Type::Tiny::XS: >>

            Rate   [P:V]   [D:V]   [P:C] [T:P v] [T:P c]
 [P:V]    9800/s      --     -7%     -8%    -41%    -72%
 [D:V]   10500/s      7%      --     -1%    -37%    -71%
 [P:C]   10609/s      8%      1%      --    -36%    -70%
 [T:P v] 16638/s     70%     58%     57%      --    -53%
 [T:P c] 35628/s    264%    239%    236%    114%      --

(Tested versions: Data::Validator 1.04 with Mouse 2.3.0,
Params::Validate 1.10, Params::Check 0.38, and Type::Params 0.045_03
with Type::Tiny::XS 0.004.)

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
 [P:V]    73643/s      --    -70%
 [T:P c] 241917/s    228%      --

=head1 DEPENDENCIES

To run this script, you will need:

L<Type::Tiny::XS>,
L<Data::Validator>, L<Params::Check>, L<Params::Validate>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

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
	'[T:P c]'  => q { $::CHK->(@::ARGS) },
	'[P:V]'    => q { validate_pos(@::ARGS, 1, 1, 0) },
});

