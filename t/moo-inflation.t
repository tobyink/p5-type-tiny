=pod

=encoding utf-8

=head1 PURPOSE

Checks that type constraints continue to work when a L<Moo> class is
inflated to a L<Moose> class. Checks that Moo::HandleMoose correctly
calls back to Type::Tiny to build Moose type constraints.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moo 1.001000 and Moose 2.0000 are not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Requires { Moo => 1.001000, Moose => 2.0000 };
use Test::Fatal;

{
	package Local::Class;
	
	use Moo;
	use BiggerLib ":all";
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

my $state = "Moose is not loaded";

for (0..1)
{
	is(
		exception { "Local::Class"->new(small => 9, big => 12) },
		undef,
		"some values that should pass their type constraint - $state",
	);

	like(
		exception { "Local::Class"->new(small => 100) },
		qr{^isa check for "small" failed: 100 is too big},
		"direct violation of type constraint - $state",
	);

	like(
		exception { "Local::Class"->new(small => 5.5) },
		qr{^isa check for "small" failed: value "5.5" did not pass type constraint "(DemoLib::)?Integer"},
		"violation of parent type constraint - $state",
	);

	like(
		exception { "Local::Class"->new(small => "five point five") },
		qr{^isa check for "small" failed: 'five point five' doesn't look like a number},
		"violation of grandparent type constraint - $state",
	);

	like(
		exception { "Local::Class"->new(small => []) },
		qr{^isa check for "small" failed: is not a string},
		"violation of great-grandparent type constraint - $state",
	);
	
	require Moose;
	"Local::Class"->meta->get_attribute("small");
	"Local::Class"->meta->get_attribute("big");
	$state = "Moose is loaded";
}

is(
	"Local::Class"->meta->get_attribute("small")->type_constraint->name,
	"BiggerLib::SmallInteger",
	"type constraint metaobject inflates from Moo to Moose",
);

done_testing;
