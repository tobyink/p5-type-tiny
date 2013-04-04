=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Moose>. Checks values that should pass
and should fail; checks error messages.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moose 2.0000 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { Moose => 2.0000 };
use Test::Fatal;

{
	package Local::Class;
	
	use Moose;
	use BiggerLib -moose, -all;
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

is(
	exception { "Local::Class"->new(small => 9, big => 12) },
	undef,
	"some values that should pass their type constraint",
);

like(
	exception { "Local::Class"->new(small => 100) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"direct violation of type constraint",
);

like(
	exception { "Local::Class"->new(small => 5.5) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of parent type constraint",
);

like(
	exception { "Local::Class"->new(small => "five point five") },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of grandparent type constraint",
);

like(
	exception { "Local::Class"->new(small => []) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of great-grandparent type constraint",
);

require Types::Standard;
ok(
	Types::Standard::Num->moose_type->equals(
		Moose::Util::TypeConstraints::find_type_constraint("Num")
	),
	"equivalence between Types::Standard types and core Moose types",
);

done_testing;
