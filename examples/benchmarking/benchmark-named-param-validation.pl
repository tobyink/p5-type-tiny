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

 Type::Params ....................................   5079 ns (196850/s)
 Params::ValidateCompiler with Type::Tiny ........   6599 ns (151515/s)
 Pure Perl Implementation with Ref::Util::XS .....   7000 ns (142857/s)
 Naive Pure Perl Implementation ..................   7560 ns (132275/s)
 Data::Validator with Mouse ......................   8440 ns (118483/s)
 Data::Validator with Type::Tiny .................   9840 ns (101626/s)
 Params::ValidateCompiler with Moose .............  11279 ns (88652/s)
 Params::ValidateCompiler with Specio ............  11320 ns (88339/s)
 Data::Validator with Moose ......................  18319 ns (54585/s)
 Params::Check with Type::Tiny ...................  21639 ns (46210/s)
 Params::Check with coderefs .....................  28079 ns (35612/s)
 MooseX::Params::Validate with Moose .............  48559 ns (20593/s)
 MooseX::Params::Validate with Type::Tiny ........  54079 ns (18491/s)

=head2 Without Type::Tiny::XS

 Pure Perl Implementation with Ref::Util::XS .....   7120 ns (140449/s)
 Naive Pure Perl Implementation ..................   7520 ns (132978/s)
 Type::Params ....................................   7960 ns (125628/s)
 Data::Validator with Mouse ......................   9000 ns (111111/s)
 Params::ValidateCompiler with Type::Tiny ........   9159 ns (109170/s)
 Params::ValidateCompiler with Moose .............  10159 ns (98425/s)
 Params::ValidateCompiler with Specio ............  11240 ns (88967/s)
 Data::Validator with Type::Tiny .................  14240 ns (70224/s)
 Data::Validator with Moose ......................  18159 ns (55066/s)
 Params::Check with Type::Tiny ...................  22039 ns (45372/s)
 Params::Check with coderefs .....................  22479 ns (44483/s)
 MooseX::Params::Validate with Moose .............  42920 ns (23299/s)
 MooseX::Params::Validate with Type::Tiny ........  43360 ns (23062/s)

=head1 ANALYSIS

Type::Params (using Type::Tiny type constraints) provides the fastest way of
checking named parameters for a function, whether or not Type::Tiny::XS
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

=head1 DEPENDENCIES

To run this script, you will need:

L<Module::Runtime>,
L<Benchmark::Featureset::ParamCheck>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.12;
use strict;
use warnings;
use Benchmark qw(:hireswallclock timeit);
use Benchmark::Featureset::ParamCheck 0.002;
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
