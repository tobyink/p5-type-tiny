=pod

=encoding utf-8

=head1 PURPOSE

Checks duck type constraints work.

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

isa_ok(CanFooBar, "Type::Tiny", "CanFooBar");
isa_ok(CanFooBaz, "Type::Tiny::Duck", "CanFooBar");

should_pass("Foo::Bar"->new, CanFooBar);
should_fail("Foo::Bar"->new, CanFooBaz);
should_pass("Foo::Baz"->new, CanFooBar);
should_pass("Foo::Baz"->new, CanFooBaz);

should_fail(undef, CanFooBar);
should_fail({}, CanFooBar);
should_fail(FooBar, CanFooBar);
should_fail(FooBaz, CanFooBar);
should_fail(CanFooBar, CanFooBar);
should_fail("Foo::Bar", CanFooBar);

done_testing;
