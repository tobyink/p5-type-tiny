=pod

=encoding utf-8

=head1 PURPOSE

Checks union type constraint subtype/supertype relationships.

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
use Type::Utils qw( union class_type );
use Types::Standard Object => { -as => "Blessed" };

{ my $x; sub FooBarOrDoesQuux () { $x ||= union(FooBarOrDoesQuux => [FooBar, DoesQuux]) } }

ok(
	FooBarOrDoesQuux->is_a_type_of(FooBarOrDoesQuux),
);

ok(
	FooBarOrDoesQuux->is_supertype_of(FooBar),
);

ok(
	FooBarOrDoesQuux->is_supertype_of(DoesQuux),
);

ok(
	FooBarOrDoesQuux->is_a_type_of(Blessed),
);

ok(
	! FooBarOrDoesQuux->is_supertype_of(Blessed),
);

ok(
	! FooBarOrDoesQuux->is_subtype_of(FooBarOrDoesQuux),
);

ok(
	FooBarOrDoesQuux->is_subtype_of(Blessed),
);

done_testing;
