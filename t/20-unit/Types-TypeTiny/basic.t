=pod

=encoding utf-8

=head1 PURPOSE

Test the L<Types::TypeTiny> bootstrap library. (That is, type constraints
used by Type::Tiny internally.)

=head1 DEPENDENCIES

This test requires L<Moose> 2.0000 and L<Mouse> 1.00. Otherwise, it is
skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

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

use Test::More;
use Test::TypeTiny -all;
use Types::TypeTiny -all;
use Moose::Util::TypeConstraints qw(find_type_constraint);

my $stringy = do {
	package Overloaded::String;
	use overload q[""] => sub { "Hello world" }, fallback => 1;
	bless {};
};

my $hashy = do {
	package Overloaded::HashRef;
	use overload q[%{}] => sub { +{} }, fallback => 1;
	bless [];
};

my $arrayey = do {
	package Overloaded::ArrayRef;
	use overload q[@{}] => sub { [] }, fallback => 1;
	bless {};
};

my $codey = do {
	package Overloaded::CodeRef;
	use overload q[&{}] => sub { sub { 42 } }, fallback => 1;
	bless [];
};

subtest "StringLike" => sub
{
	my $type = StringLike;
	should_pass( "Hello", $type );
	should_pass( "", $type );
	should_pass( CodeLike, $type, 'Type::Tiny constraint object passes type constraint StringLike' );
	should_pass( $stringy, $type );
	should_fail( {}, $type );
	should_fail( undef, $type );
};

subtest "ArrayLike" => sub
{
	my $type = ArrayLike;
	should_pass( [], $type );
	should_pass( $arrayey, $type );
	should_fail( {}, $type );
	should_fail( bless([], 'XXX'), $type );
	should_fail( undef, $type );
};

subtest "HashLike" => sub
{
	my $type = HashLike;
	should_pass( {}, $type );
	should_pass( $hashy, $type );
	should_fail( [], $type );
	should_fail( bless({}, 'XXX'), $type );
	should_fail( undef, $type );
};

subtest "CodeLike" => sub
{
	my $type = CodeLike;
	should_pass( sub { 42 }, $type );
	should_pass( CodeLike, $type, 'Type::Tiny constraint object passes type constraint CodeLike' );
	should_pass( $codey, $type );
	should_fail( {}, $type );
	should_fail( bless(sub {42}, 'XXX'), $type );
	should_fail( undef, $type );
};

subtest "TypeTiny" => sub
{
	my $type = TypeTiny;
	should_pass( ArrayLike, $type, 'Type::Tiny constraint object passes type constraint TypeTiny' );
	should_fail( {}, $type );
	should_fail( sub { 42 }, $type );
	should_fail( find_type_constraint("Int"), $type, 'Moose constraint object fails type constraint TypeTiny' );
	should_fail( Mouse::Util::TypeConstraints::find_type_constraint("Int"), $type, 'Mouse constraint object fails type constraint TypeTiny' );
	should_fail( undef, $type );
};

done_testing;
