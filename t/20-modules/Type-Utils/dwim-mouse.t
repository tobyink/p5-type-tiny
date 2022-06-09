=pod

=encoding utf-8

=head1 PURPOSE

Checks Mouse type constraints, and L<MouseX::Types> type constraints are
picked up by C<dwim_type> from L<Type::Utils>.

=head1 DEPENDENCIES

Mouse 1.00 and MouseX::Types 0.06; skipped otherwise.

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
use Test::Requires { "Mouse" => "1.00" };
use Test::Requires { "MouseX::Types" => "0.06" };
use Test::TypeTiny;

use Mouse;
use Mouse::Util::TypeConstraints qw(:all);
use Type::Utils 0.015 qw(dwim_type);

# Creating a type constraint with Mouse
subtype "Two", as "Int", where { $_ eq 2 };

my $two  = dwim_type("Two");
my $twos = dwim_type("ArrayRef[Two]");

isa_ok($two, 'Type::Tiny', '$two');
isa_ok($twos, 'Type::Tiny', '$twos');

should_pass(2, $two);
should_fail(3, $two);
should_pass([2, 2, 2], $twos);
should_fail([2, 3, 2], $twos);

# Creating a type constraint with MouseX::Types
{
	package MyTypes;
	use MouseX::Types -declare => ["Three"];
	use MouseX::Types::Moose "Int";
	
	subtype Three, as Int, where { $_ eq 3 };
	
	$INC{'MyTypes.pm'} = __FILE__;
}

# Note that MouseX::Types namespace-prefixes its types.
my $three = dwim_type("MyTypes::Three");
my $threes = dwim_type("ArrayRef[MyTypes::Three]");

isa_ok($three, 'Type::Tiny', '$three');
isa_ok($threes, 'Type::Tiny', '$threes');

should_pass(3, $three);
should_fail(4, $three);
should_pass([3, 3, 3], $threes);
should_fail([3, 4, 3], $threes);

{
	my $testclass = 'Local::Some::Class';
	my $fallback  = dwim_type($testclass);
	should_pass(bless({}, $testclass), $fallback);
	should_fail(bless({}, 'main'), $fallback);
	
	my $fallbackp = dwim_type("ArrayRef[$testclass]");
	should_pass([bless({}, $testclass)], $fallbackp);
	should_pass([], $fallbackp);
	should_fail([bless({}, 'main')], $fallbackp);
	
	my $fallbacku = dwim_type("ArrayRef[$testclass]", fallback => []);
	is($fallbacku, undef);
}

{
	my $testclass = 'Local::Some::Class';
	my $fallback  = dwim_type("$testclass\::");
	should_pass(bless({}, $testclass), $fallback);
	should_fail(bless({}, 'main'), $fallback);
	
	my $fallbackp = dwim_type("ArrayRef[$testclass\::]");
	should_pass([bless({}, $testclass)], $fallbackp);
	should_pass([], $fallbackp);
	should_fail([bless({}, 'main')], $fallbackp);
}



done_testing;
