=pod

=encoding utf-8

=head1 PURPOSE

Checks role type constraints work.

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

isa_ok(DoesQuux, "Type::Tiny", "DoesQuux");
isa_ok(DoesQuux, "Type::Tiny::Role", "DoesQuux");

should_fail("Foo::Bar"->new, DoesQuux);
should_pass("Foo::Baz"->new, DoesQuux);

should_fail(undef, DoesQuux);
should_fail({}, DoesQuux);
should_fail(FooBar, DoesQuux);
should_fail(FooBaz, DoesQuux);
should_fail(DoesQuux, DoesQuux);
should_fail("Quux", DoesQuux);

is(
	'Type::Tiny::Role'->new(  role => 'Xyzzy'  )->inline_check('$x'),
	'Type::Tiny::Role'->new({ role => 'Xyzzy' })->inline_check('$x'),
	'constructor can be passed a hash or hashref',
);

done_testing;
