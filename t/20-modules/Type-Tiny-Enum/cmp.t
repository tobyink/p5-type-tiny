=pod

=encoding utf-8

=head1 PURPOSE

Test new type comparison stuff with Type::Tiny::Enum.

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

use Type::Tiny;
use Type::Utils qw(enum);
use Test::More;
use Test::TypeTiny;

my $animals = enum Animals => [qw( cat dog mouse rabbit cow horse sheep goat pig zebra lion )];
my $farmAnimals = enum FarmAnimals => [qw( cow horse sheep goat pig )];
my $petAnimals = enum PetAnimals => [qw( cat dog mouse rabbit )];
my $wildAnimals = enum WildAnimals => [qw( zebra lion )];
my $catAnimals = enum CatAnimals => [qw( cat lion )];
my $catAnimals2 = enum FelineAnimals => [qw( lion cat )];

my @combos = (
	[ $animals, $animals, Type::Tiny::CMP_EQUAL ],
	[ $animals, $farmAnimals, Type::Tiny::CMP_SUPERTYPE ],
	[ $animals, $petAnimals, Type::Tiny::CMP_SUPERTYPE ],
	[ $animals, $wildAnimals, Type::Tiny::CMP_SUPERTYPE ],
	[ $farmAnimals, $animals, Type::Tiny::CMP_SUBTYPE ],
	[ $farmAnimals, $farmAnimals, Type::Tiny::CMP_EQUAL ],
	[ $farmAnimals, $petAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $farmAnimals, $wildAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $petAnimals, $animals, Type::Tiny::CMP_SUBTYPE ],
	[ $petAnimals, $farmAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $petAnimals, $petAnimals, Type::Tiny::CMP_EQUAL ],
	[ $petAnimals, $wildAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $wildAnimals, $animals, Type::Tiny::CMP_SUBTYPE ],
	[ $wildAnimals, $farmAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $wildAnimals, $petAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $wildAnimals, $wildAnimals, Type::Tiny::CMP_EQUAL ],
	[ $petAnimals, $catAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $catAnimals, $petAnimals, Type::Tiny::CMP_UNKNOWN ],
	[ $catAnimals, $catAnimals2, Type::Tiny::CMP_EQUAL ],
	[ $catAnimals2, $catAnimals, Type::Tiny::CMP_EQUAL ],
);

for (@combos) {
	my ($t1, $t2, $r) = @$_;
	is(Type::Tiny::cmp($t1, $t2), $r, "Relationship between $t1 and $t2");
}

done_testing;
