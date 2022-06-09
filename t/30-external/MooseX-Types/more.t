=pod

=encoding utf-8

=head1 PURPOSE

More checks between Type::Tiny and L<MooseX::Types>.

This started out as an example of making a parameterized C<< Not[] >>
type constraint, but worked out as a nice test case.

=head1 DEPENDENCIES

MooseX::Types 0.35; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "MooseX::Types::Moose" => "0.35" };
use Test::TypeTiny;

BEGIN {
	package MooseX::Types::Not;
	use Type::Library -base;
	use Types::TypeTiny;
	__PACKAGE__->add_type({
		name                 => "Not",
		constraint           => sub {  !!0  },
		inlined              => sub { "!!0" },
		constraint_generator => sub { Types::TypeTiny::to_TypeTiny(shift)->complementary_type },
	});
	$INC{"MooseX/Types/Not.pm"} = __FILE__;
};

use MooseX::Types::Not qw(Not);
use MooseX::Types::Moose qw(Int);

isa_ok($_, "Moose::Meta::TypeConstraint", "$_") for Not, Int, Not[Int], Not[Not[Int]];

should_fail(1.1,   Int);
should_fail(undef, Int);
should_fail([],    Int);
should_pass(2,     Int);

should_pass(1.1,   Not[Int]);
should_pass(undef, Not[Int]);
should_pass([],    Not[Int]);
should_fail(2,     Not[Int]);

should_fail(1.1,   Not[Not[Int]]);
should_fail(undef, Not[Not[Int]]);
should_fail([],    Not[Not[Int]]);
should_pass(2,     Not[Not[Int]]);

# 'Not' alone behaves as 'Not[Any]'
should_fail(1.1,   Not);
should_fail(undef, Not);
should_fail([],    Not);
should_fail(2,     Not);

done_testing;
