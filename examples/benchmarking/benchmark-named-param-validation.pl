=pod

=encoding utf-8

=head1 DESCRIPTION

Let's use L<Benchmark::Featureset::ParamCheck> to see how fast
L<Type::Params> is compared with other modules for validating
named parameters. (Hint: very fast.)

=head1 RESULTS

The results of running the script on a fairly low-powered laptop.
Each parameter checking implementation is called 250,000 times.
The table below displays the average time taken for each call in
nanoseconds.

=head2 With Type::Tiny::XS

 Type::Params with Type::Tiny ....................   1560 ns (641025/s)
 Params::ValidationCompiler with Type::Tiny ......   1679 ns (595238/s)
 Type::Params with Moose .........................   1719 ns (581395/s)
 Pure Perl Implementation with Ref::Util::XS .....   1840 ns (543478/s)
 Naive Pure Perl Implementation ..................   2039 ns (490196/s)
 Type::Params with Specio ........................   2439 ns (409836/s)
 Params::ValidationCompiler with Specio ..........   2480 ns (403225/s)
 Type::Params with Mouse .........................   2519 ns (396825/s)
 Params::ValidationCompiler with Moose ...........   2560 ns (390624/s)
 Data::Validator with Mouse ......................   2599 ns (384615/s)
 Params::Validate with Type::Tiny ................   2800 ns (357142/s)
 Data::Validator with Type::Tiny .................   2920 ns (342465/s)
 Params::Validate ................................   3399 ns (294117/s)
 Data::Validator with Moose ......................   4920 ns (203252/s)
 Params::Check with Type::Tiny ...................   5279 ns (189393/s)
 Params::Check with coderefs .....................   6359 ns (157232/s)
 MooseX::Params::Validate with Moose .............  10520 ns (95057/s)
 MooseX::Params::Validate with Type::Tiny ........  10520 ns (95057/s)
 Type::Params with Type::Nano ....................  10679 ns (93632/s)

=head2 Without Type::Tiny::XS

 Pure Perl Implementation with Ref::Util::XS .....   1839 ns (543478/s)
 Type::Params with Type::Tiny ....................   1959 ns (510204/s)
 Naive Pure Perl Implementation ..................   2039 ns (490196/s)
 Type::Params with Moose .........................   2079 ns (480769/s)
 Params::ValidationCompiler with Type::Tiny ......   2119 ns (471698/s)
 Type::Params with Specio ........................   2439 ns (409836/s)
 Params::ValidationCompiler with Specio ..........   2520 ns (396825/s)
 Params::ValidationCompiler with Moose ...........   2599 ns (384615/s)
 Params::Validate ................................   3359 ns (297619/s)
 Type::Params with Mouse .........................   3760 ns (265957/s)
 Params::Validate with Type::Tiny ................   3920 ns (255102/s)
 Data::Validator with Type::Tiny .................   4359 ns (229357/s)
 Data::Validator with Mouse ......................   4640 ns (215517/s)
 Data::Validator with Moose ......................   5399 ns (185185/s)
 Params::Check with coderefs .....................   6359 ns (157232/s)
 Params::Check with Type::Tiny ...................   6359 ns (157232/s)
 MooseX::Params::Validate with Moose .............  10440 ns (95785/s)
 MooseX::Params::Validate with Type::Tiny ........  10440 ns (95785/s)
 Type::Params with Type::Nano ....................  10520 ns (95057/s)

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) is the fastest framework
for checking named parameters for a function, whether or not Type::Tiny::XS
is available.

Params::ValidationCompiler (also using Type::Tiny type constraints) is very
nearly as fast.

Params::ValidationCompiler using other type constraints is also quite fast,
and when Type::Tiny::XS is not available, Moose and Specio constraints run
almost as fast as Type::Tiny constraints.

Data::Validator is acceptably fast.

Params::Check is fairly slow, and MooseX::Params::Validate very slow.

Type::Tiny::XS seems to slow down MooseX::Params::Validate for some strange
reason.

Type::Nano is slow. (But it's not written for speed!)

=head1 DEPENDENCIES

To run this script, you will need:

L<Module::Runtime>,
L<Benchmark::Featureset::ParamCheck>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.12;
use strict;
use warnings;
use Benchmark qw(:hireswallclock timeit);
use Benchmark::Featureset::ParamCheck 0.006;
use Module::Runtime qw(use_module);

my $data = 'Benchmark::Featureset::ParamCheck'->trivial_named_data;
my @impl = 'Benchmark::Featureset::ParamCheck'->implementations;
my $iter = 250_000;

say for
	map {
		sprintf(
			'%s %s %6d ns (%d/s)',
			$_->[0]->long_name,
			'.' x (48 - length($_->[0]->long_name)),
			1_000_000_000 * $_->[1]->cpu_a / $iter,
			$iter / $_->[1]->cpu_a,
		);
	}
	sort {
		$a->[1]->cpu_a <=> $b->[1]->cpu_a;
	}
	map {
		my $pkg = use_module($_);
		[ $pkg, timeit 1, sub { $pkg->run_named_check($iter, $data) } ];
	} @impl;
