=pod

=encoding utf-8

=head1 PURPOSE

Checks class type constraints work.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

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
use Test::TypeTiny;

use BiggerLib qw( :types );

isa_ok(FooBar, "Type::Tiny", "FooBar");
isa_ok(FooBar, "Type::Tiny::Class", "FooBar");
isa_ok(FooBaz, "Type::Tiny", "FooBaz");
isa_ok(FooBaz, "Type::Tiny::Class", "FooBaz");

isa_ok(FooBar->new, "Foo::Bar", "FooBar->new");
isa_ok(FooBaz->new, "Foo::Baz", "FooBaz->new");
isa_ok(FooBar->class->new, "Foo::Bar", "FooBar->class->new");
isa_ok(FooBaz->class->new, "Foo::Baz", "FooBaz->class->new");

should_pass("Foo::Bar"->new, FooBar);
should_pass("Foo::Baz"->new, FooBar);
should_fail("Foo::Bar"->new, FooBaz);
should_pass("Foo::Baz"->new, FooBaz);

should_fail(undef, FooBar);
should_fail(undef, FooBaz);
should_fail({}, FooBar);
should_fail({}, FooBaz);
should_fail(FooBar, FooBar);
should_fail(FooBar, FooBaz);
should_fail(FooBaz, FooBar);
should_fail(FooBaz, FooBaz);
should_fail("Foo::Bar", FooBar);
should_fail("Foo::Bar", FooBaz);
should_fail("Foo::Baz", FooBar);
should_fail("Foo::Baz", FooBaz);

is(
	ref(FooBar->new),
	ref(FooBar->class->new),
	'DWIM Type::Tiny::Class::new',
);

is(
	'Type::Tiny::Class'->new(  class => 'Xyzzy'  )->inline_check('$x'),
	'Type::Tiny::Class'->new({ class => 'Xyzzy' })->inline_check('$x'),
	'constructor can be passed a hash or hashref',
);

done_testing;
