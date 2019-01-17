=pod

=encoding utf-8

=head1 PURPOSE

Test L<Types::TypeTiny::to_TypeTiny> pseudo-coercion.

=head1 DEPENDENCIES

This test requires L<Moose> 2.0000, L<Mouse> 1.00, and L<Moo> 1.000000.
Otherwise, it is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

# Test::Requires calls ->import on Moose/Mouse, so be sure
# to import them into dummy packages.
{ package XXX; use Test::Requires { Moose => '2.0000' } };
{ package YYY; use Test::Requires { Mouse => '1.00' } };
{ package ZZZ; use Test::Requires { Moo   => '1.000000' } };

use Test::More;
use Test::TypeTiny -all;
use Types::TypeTiny -all;
use Moose::Util::TypeConstraints qw(find_type_constraint);

ok(TypeTiny->has_coercion, "TypeTiny->has_coercion");

subtest "Coercion from Moose type constraint object" => sub
{
	my $orig = find_type_constraint("Int");
	my $type = to_TypeTiny $orig;
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted a Moose type constraint to a Type::Tiny one');
	is($type->name, 'Int', '... which has the correct name');
	ok($type->can_be_inlined, '... and which can be inlined');
	note $type->inline_check('$X');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};

## We don't do this for Moose for some reason.
#
#	is(
#		$type->get_message(3.3),
#		$orig->get_message(3.3),
#		'... and provides proper message',
#	);
};

subtest "Coercion from Mouse type constraint object" => sub
{
	my $orig = Mouse::Util::TypeConstraints::find_type_constraint("Int");
	my $type = to_TypeTiny $orig;
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted a Mouse type constraint to a Type::Tiny one');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
	is(
		$type->get_message(3.3),
		$orig->get_message(3.3),
		'... and provides proper message',
	);
};

subtest "Coercion from predicate-like coderef" => sub
{
	my $type = to_TypeTiny sub { $_[0] =~ /\A-?[0-9]+\z/ };
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
};

subtest "Coercion from assertion-like coderef" => sub
{
	my $type = to_TypeTiny sub { $_[0] =~ /\A-?[0-9]+\z/ or die("not an integer") };
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
	like(
		$type->validate(3.3),
		qr/\Anot an integer/,
		'... and provides proper message',
	);
};

subtest "Coercion from Sub::Quote coderef" => sub
{
	require Sub::Quote;
	my $type = to_TypeTiny Sub::Quote::quote_sub(q{ $_[0] =~ /\A-?[0-9]+\z/ });
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	ok($type->can_be_inlined, '... which can be inlined');
	note $type->inline_check('$X');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
};

done_testing;
