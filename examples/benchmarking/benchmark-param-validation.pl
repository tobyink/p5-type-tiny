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

 Type::Params ....................................   2640 ns (378787/s)
 Params::ValidationCompiler with Type::Tiny ......   3120 ns (320512/s)
 Pure Perl Implementation with Ref::Util::XS .....   3639 ns (274725/s)
 Naive Pure Perl Implementation ..................   4600 ns (217391/s)
 Params::ValidationCompiler with Specio ..........  11719 ns (85324/s)
 Params::ValidationCompiler with Moose ...........  12079 ns (82781/s)
 Data::Validator with Mouse ......................  51760 ns (19319/s)
 Data::Validator with Type::Tiny .................  51920 ns (19260/s)
 Data::Validator with Moose ......................  52120 ns (19186/s)
 MooseX::Params::Validate with Moose .............  83080 ns (12036/s)
 MooseX::Params::Validate with Type::Tiny ........  84839 ns (11786/s)

=head2 Without Type::Tiny::XS

 Pure Perl Implementation with Ref::Util::XS .....   3560 ns (280898/s)
 Naive Pure Perl Implementation ..................   4479 ns (223214/s)
 Type::Params ....................................   7879 ns (126903/s)
 Params::ValidationCompiler with Type::Tiny ......   8319 ns (120192/s)
 Params::ValidationCompiler with Specio ..........  11800 ns (84745/s)
 Params::ValidationCompiler with Moose ...........  12159 ns (82236/s)
 Data::Validator with Type::Tiny .................  51039 ns (19592/s)
 Data::Validator with Moose ......................  51559 ns (19394/s)
 Data::Validator with Mouse ......................  51760 ns (19319/s)
 MooseX::Params::Validate with Type::Tiny ........  82800 ns (12077/s)
 MooseX::Params::Validate with Moose .............  93160 ns (10734/s)

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) provides the fastest convenient
way of checking positional parameters for a function, whether or not Type::Tiny::XS
is available.

The only way to beat it is to write your own type checking in longhand,
but if Type::Tiny::XS is installed, you probably still won't be able
to match Type::Params' speed.

Params::ValidationCompiler (also using Type::Tiny type constraints) is very
nearly as fast.

Params::ValidationCompiler using other type constraints is also quite fast,
and when Type::Tiny::XS is not available, Moose and Specio constraints run
almost as fast as Type::Tiny constraints.

Data::Validator and MooseX::Params::Validate are far slower.

=head1 DEPENDENCIES

To run this script, you will need:

L<Module::Runtime>,
L<Benchmark::Featureset::ParamCheck>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.12;
use strict;
use warnings;
use Benchmark qw(:hireswallclock timeit);
use Benchmark::Featureset::ParamCheck 0.002;
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
