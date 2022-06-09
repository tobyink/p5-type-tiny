=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints can be made inlinable using L<Sub::Quote>.

=head1 DEPENDENCIES

Test is skipped if Sub::Quote is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires "Sub::Quote";
use Test::TypeTiny;

use Sub::Quote;
use Type::Tiny;
use Types::Standard qw( ArrayRef Int );

my $Type1 = "Type::Tiny"->new(
	name       => "Type1",
	constraint => quote_sub q{ $_[0] eq q(42) },
);

should_fail(41, $Type1);
should_pass(42, $Type1);
ok($Type1->can_be_inlined, 'constraint built using quote_sub and $_[0] can be inlined')
	and note $Type1->inline_check('$value');

my $Type2 = "Type::Tiny"->new(
	name       => "Type2",
	constraint => quote_sub q{ $_ eq q(42) },
);

should_fail(41, $Type2);
should_pass(42, $Type2);
ok($Type2->can_be_inlined, 'constraint built using quote_sub and $_[0] can be inlined')
	and note $Type2->inline_check('$value');

my $Type3 = "Type::Tiny"->new(
	name       => "Type3",
	constraint => quote_sub q{ my ($n) = @_; $n eq q(42) },
);

should_fail(41, $Type3);
should_pass(42, $Type3);
ok($Type3->can_be_inlined, 'constraint built using quote_sub and @_ can be inlined')
	and note $Type3->inline_check('$value');

my $Type4 = "Type::Tiny"->new(
	name       => "Type4",
	parent     => Int,
	constraint => quote_sub q{ $_[0] >= 42 },
);

should_fail(41, $Type4);
should_pass(42, $Type4);
should_pass(43, $Type4);
should_fail(44.4, $Type4);
ok($Type4->can_be_inlined, 'constraint built using quote_sub and parent type can be inlined')
	and note $Type4->inline_check('$value');

my $Type5 = "Type::Tiny"->new(
	name       => "Type5",
	parent     => Int,
	constraint => quote_sub q{ $_[0] >= $x }, { '$x' => \42 },
);

should_fail(41, $Type5);
should_pass(42, $Type5);
should_pass(43, $Type5);
should_fail(44.4, $Type5);
TODO: {
	local $TODO = "captures not supported yet";
	ok($Type5->can_be_inlined, 'constraint built using quote_sub and captures can be inlined');
};

my $Type6 = "Type::Tiny"->new(
	name       => "Type6",
	parent     => Int->create_child_type(constraint => sub { 999 }),
	constraint => quote_sub q{ $_[0] >= 42 },
);

should_fail(41, $Type6);
should_pass(42, $Type6);
should_pass(43, $Type6);
should_fail(44.4, $Type6);
ok(!$Type6->can_be_inlined, 'constraint built using quote_sub and non-inlinable parent cannot be inlined');

my $Type7 = ArrayRef([Int]) & quote_sub q{ @$_ > 1 and @$_ < 4 };

should_pass([1,2,3], $Type7);
should_fail([1,2.1,3], $Type7);
should_fail([1], $Type7);
should_fail([1,2,3,4], $Type7);
ok($Type7->can_be_inlined, 'constraint built as an intersection of an inlinable type constraint and a quoted sub can be inlined');

note($Type7->inline_check('$VAR'));

done_testing;
