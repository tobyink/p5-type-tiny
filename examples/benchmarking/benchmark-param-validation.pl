=pod

=encoding utf-8

=head1 DESCRIPTION

Let's use L<Benchmark::Featureset::ParamCheck> to see how fast
L<Type::Params> is compared with other modules for validating
positional parameters. (Hint: very fast.)

=head1 RESULTS

The results of running the script on a fairly low-powered laptop.
Each parameter checking implementation is called 250,000 times.
The table below displays the average time taken for each call in
nanoseconds.

=head2 With Type::Tiny::XS

 Pure Perl Implementation with Ref::Util::XS .....    479 ns (2083333/s)
 Type::Params with Type::Tiny ....................    519 ns (1923076/s)
 Params::ValidationCompiler with Type::Tiny ......    560 ns (1785714/s)
 Naive Pure Perl Implementation ..................    640 ns (1562499/s)
 Type::Params with Moose .........................    799 ns (1250000/s)
 Params::ValidationCompiler with Specio ..........   1399 ns (714285/s)
 Params::ValidationCompiler with Moose ...........   1479 ns (675675/s)
 Type::Params with Mouse .........................   1520 ns (657894/s)
 Type::Params with Specio ........................   1560 ns (641025/s)
 Params::Validate with Type::Tiny ................   2199 ns (454545/s)
 Params::Validate ................................   2760 ns (362318/s)
 Data::Validator with Mouse ......................   5560 ns (179856/s)
 Data::Validator with Type::Tiny .................   5600 ns (178571/s)
 Data::Validator with Moose ......................   5680 ns (176056/s)
 MooseX::Params::Validate with Moose .............   8079 ns (123762/s)
 MooseX::Params::Validate with Type::Tiny ........   8120 ns (123152/s)
 Type::Params with Type::Nano ....................   9160 ns (109170/s)

=head2 Without Type::Tiny::XS

 Pure Perl Implementation with Ref::Util::XS .....    479 ns (2083333/s)
 Naive Pure Perl Implementation ..................    599 ns (1666666/s)
 Type::Params with Type::Tiny ....................   1079 ns (925925/s)
 Params::ValidationCompiler with Type::Tiny ......   1120 ns (892857/s)
 Type::Params with Moose .........................   1240 ns (806451/s)
 Type::Params with Specio ........................   1520 ns (657894/s)
 Params::ValidationCompiler with Specio ..........   1560 ns (641025/s)
 Params::ValidationCompiler with Moose ...........   1599 ns (625000/s)
 Params::Validate ................................   2640 ns (378787/s)
 Type::Params with Mouse .........................   2760 ns (362318/s)
 Params::Validate with Type::Tiny ................   3279 ns (304878/s)
 Data::Validator with Moose ......................   5760 ns (173611/s)
 Data::Validator with Type::Tiny .................   5799 ns (172413/s)
 Data::Validator with Mouse ......................   5800 ns (172413/s)
 MooseX::Params::Validate with Type::Tiny ........   8079 ns (123762/s)
 MooseX::Params::Validate with Moose .............   8120 ns (123152/s)
 Type::Params with Type::Nano ....................   9119 ns (109649/s)

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) is the fastest framework for
checking positional parameters for a function, whether or not Type::Tiny::XS
is available.

The only way to beat it is to write your own type checking in longhand,
but if Type::Tiny::XS is installed, hand-rolled code might still be slower.

Params::ValidationCompiler (also using Type::Tiny type constraints) is very
nearly as fast.

Params::ValidationCompiler using other type constraints is also quite fast,
and when Type::Tiny::XS is not available, Moose and Specio constraints run
almost as fast as Type::Tiny constraints.

Data::Validator and MooseX::Params::Validate are far slower.

Type::Nano is slow. (But it's not written for speed!)

=head1 DEPENDENCIES

To run this script, you will need:

L<Module::Runtime>,
L<Benchmark::Featureset::ParamCheck>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.12;
use strict;
use warnings;
use Benchmark qw(:hireswallclock timeit);
use Benchmark::Featureset::ParamCheck 0.006;
use Module::Runtime qw(use_module);

my $data = 'Benchmark::Featureset::ParamCheck'->trivial_positional_data;
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
		$pkg->accept_array
			? [ $pkg, timeit 1, sub { $pkg->run_positional_check($iter, @$data) } ]
			: ()
	}
	@impl;
