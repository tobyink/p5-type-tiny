=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Moo>. Checks values that should pass
and should fail; checks error messages.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moo 1.000000 is not available.

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
use Test::Requires { Moo => 1.000000 };
use Test::Fatal;

{
	package Local::Class;
	
	use Moo;
	use BiggerLib ":all";
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

is(
	exception { "Local::Class"->new(small => 9, big => 12) },
	undef,
	"some values that should pass their type constraint",
);

isnt(
	exception { "Local::Class"->new(small => 100) },
	undef,
	"direct violation of type constraint",
);

isnt(
	exception { "Local::Class"->new(small => 5.5) },
	undef,
	"violation of parent type constraint",
);

isnt(
	exception { "Local::Class"->new(small => "five point five") },
	undef,
	"violation of grandparent type constraint",
);

isnt(
	exception { "Local::Class"->new(small => []) },
	undef,
	"violation of great-grandparent type constraint",
);

done_testing;
