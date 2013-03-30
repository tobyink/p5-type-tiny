=pod

=encoding utf-8

=head1 PURPOSE

Type library used in several test cases.

Defines types C<SmallInteger> and C<BigInteger>.
Defines classes C<Foo::Bar> and C<Foo::Baz> along with correponding
C<FooBar> and C<FooBaz> class type constraints; defines role C<Quux>
and the C<DoesQuux> role type constraint.

Library extends DemoLib.pm.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package BiggerLib;

use strict;
use warnings;

use Type::Library::Util;

use base "Type::Library";

extends "DemoLib";

declare "SmallInteger",
	as "Integer",
	where { $_ < 10 }
	message { "$_ is too big" };

declare "BigInteger",
	as "Integer",
	where { $_ >= 10 };

{
	package Quux;
	our $VERSION = 1;
}

declare "DoesQuux", role "Quux";

{
	package Foo::Bar;
	sub new { my $c = shift; bless {@_}, $c }
}

declare "FooBar", class "Foo::Bar";

{
	package Foo::Baz;
	use base "Foo::Bar";
	sub DOES {
		return 1 if $_[1] eq 'Quux';
		$_[0]->isa($_[0]);
	}
}

declare "FooBaz", class "Foo::Baz";

# No sugar for coercion yet
require Type::Coercion;
my $small = __PACKAGE__->get_type("SmallInteger");
my $big   = __PACKAGE__->get_type("BigInteger");
$small->{coercion} = "Type::Coercion"->new;
$big->{coercion} = "Type::Coercion"->new;

$small->coercion->add_type_coercions(
	$big, sub { abs($_) % 10 },
);

$big->coercion->add_type_coercions(
	$small, sub { abs($_) + 10 },
);

1;
