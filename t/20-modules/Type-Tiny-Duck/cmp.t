=pod

=encoding utf-8

=head1 PURPOSE

Test new type comparison stuff with Type::Tiny::Duck objects.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Type::Utils qw(duck_type);

my $type1 = duck_type Type1 => [qw( foo bar )];
my $type2 = duck_type Type2 => [qw( bar foo )];
my $type3 = duck_type Type3 => [qw( foo bar baz )];

ok_subtype($type1 => $type2, $type3);
ok_subtype($type2 => $type1, $type3);
ok($type1->equals($type2));
ok($type2->equals($type1));
ok($type3->is_subtype_of($type2));
ok($type2->is_supertype_of($type3));

ok($type1->equals($type2->create_child_type));
ok($type2->equals($type1->create_child_type));
ok($type3->is_subtype_of($type2->create_child_type));
ok($type2->is_supertype_of($type3->create_child_type));

ok($type1->create_child_type->equals($type2));
ok($type2->create_child_type->equals($type1));
ok($type3->create_child_type->is_subtype_of($type2));
ok($type2->create_child_type->is_supertype_of($type3));

done_testing;
