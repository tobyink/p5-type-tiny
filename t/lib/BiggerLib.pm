=pod

=encoding utf-8

=head1 PURPOSE

Type library used in several test cases.

Defines types C<SmallInteger>, C<BigInteger> and C<Distance>.
Defines classes C<Foo::Bar> and C<Foo::Baz> along with correponding
C<FooBar> and C<FooBaz> class type constraints; defines role C<Quux>
and the C<DoesQuux> role type constraint.

Library extends DemoLib.pm.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package BiggerLib;

use strict;
use warnings;

use Type::Utils qw(:all);

use Type::Library -base;

extends "DemoLib";
extends "Types::Standard";

declare "SmallInteger",
	as "Integer",
	where { no warnings; $_ < 10 }
	message { no warnings; "$_ is too big" };

declare "BigInteger",
	as "Integer",
	where { no warnings; $_ >= 10 };

{
	package Quux;
	our $VERSION = 1;
}

role_type "DoesQuux", { role => "Quux" };

{
	package Foo::Bar;
	sub new { my $c = shift; bless {@_}, $c }
	sub foo { 1 }
	sub bar { 2 }
}

class_type "FooBar", { class => "Foo::Bar" };

{
	package Foo::Baz;
	our @ISA = "Foo::Bar";
	sub DOES {
		return 1 if $_[1] eq 'Quux';
		$_[0]->isa($_[0]);
	}
	sub foo { 3 }
	sub baz { 4 }
}

class_type "Foo::Baz";
duck_type "CanFooBar", [qw/ foo bar /];
duck_type "CanFooBaz", [qw/ foo baz /];

coerce "SmallInteger",
	from BigInteger   => via { abs($_) % 10 },
	from ArrayRef     => via { 1 };

coerce "BigInteger",
	from SmallInteger => via { abs($_) + 10 },
	from ArrayRef     => via { 100 };

declare_coercion "ArrayRefFromAny", to_type "ArrayRef", from "Any", q { [$_] };

declare_coercion "ArrayRefFromPiped", to_type "ArrayRef", from "Str", q { [split /\\|/] };

1;
