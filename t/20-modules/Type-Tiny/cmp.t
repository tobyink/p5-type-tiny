=pod

=encoding utf-8

=head1 PURPOSE

Test new type comparison stuff with Type::Tiny objects.

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
use Test::More;
use Test::TypeTiny;

my $string = Type::Tiny->new(
	constraint => sub { defined($_) && !ref($_) },
);

my $integer = $string->where(sub { /^-?[0-9]+$/ and not $_ eq '-0' });

my $natural = $integer->where(sub { $_ >= 0 });

my $digit = $natural->where(sub { $_ < 10 });

my $undef = Type::Tiny->new(constraint => sub { !defined });

my ($stringX, $integerX, $naturalX, $digitX) = map {
	$_->plus_coercions($undef, sub { 0 });
} ($string, $integer, $natural, $digit);

ok_subtype($string => $integer, $natural, $digit, $stringX, $integerX, $naturalX, $digitX);
ok_subtype($stringX => $string, $integer, $natural, $digit, $integerX, $naturalX, $digitX);
ok_subtype($integer => $natural, $digit, $integerX, $naturalX, $digitX);
ok_subtype($integerX => $integer, $natural, $digit, $naturalX, $digitX);
ok_subtype($natural => $digit, $naturalX, $digitX);
ok_subtype($naturalX => $natural, $digit, $digitX);
ok_subtype($digit => $digitX);
ok_subtype($digitX => $digit);

ok !$string->is_a_type_of($undef);
ok !$undef->is_a_type_of($string);
ok !$digit->is_a_type_of($undef);
ok !$undef->is_a_type_of($digit);
ok !$stringX->is_a_type_of($undef);
ok !$undef->is_a_type_of($stringX);
ok !$digitX->is_a_type_of($undef);
ok !$undef->is_a_type_of($digitX);

is(Type::Tiny::cmp($string, $digit), Type::Tiny::CMP_SUPERTYPE);
is(Type::Tiny::cmp($stringX, $digit), Type::Tiny::CMP_SUPERTYPE);
is(Type::Tiny::cmp($string, $digitX), Type::Tiny::CMP_SUPERTYPE);
is(Type::Tiny::cmp($stringX, $digitX), Type::Tiny::CMP_SUPERTYPE);

is(Type::Tiny::cmp($digit, $string), Type::Tiny::CMP_SUBTYPE);
is(Type::Tiny::cmp($digit, $stringX), Type::Tiny::CMP_SUBTYPE);
is(Type::Tiny::cmp($digitX, $string), Type::Tiny::CMP_SUBTYPE);
is(Type::Tiny::cmp($digitX, $stringX), Type::Tiny::CMP_SUBTYPE);

is(Type::Tiny::cmp($string, $stringX), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($stringX, $string), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($digit, $digitX), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($digitX, $digit), Type::Tiny::CMP_EQUAL);

is(Type::Tiny::cmp($string, $undef), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($stringX, $undef), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($undef, $string), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($undef, $stringX), Type::Tiny::CMP_UNKNOWN);

my $type1 = Type::Tiny->new(constraint => '$_ eq "FLIBBLE"');
my $type2 = Type::Tiny->new(constraint => '$_ eq "FLIBBLE"');
my $type3 = Type::Tiny->new(constraint => '$_ eq "FLOBBLE"');

is(Type::Tiny::cmp($type1, $type2), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($type1, $type3), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($type2, $type1), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($type2, $type3), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($type3, $type1), Type::Tiny::CMP_UNKNOWN);
is(Type::Tiny::cmp($type3, $type2), Type::Tiny::CMP_UNKNOWN);

is(Type::Tiny::cmp($type1, $type2->create_child_type), Type::Tiny::CMP_EQUAL);
is(Type::Tiny::cmp($type1, $type2->where(sub { 0 })), Type::Tiny::CMP_SUPERTYPE);

{
	package MyBleh;
	use Type::Registry 't';
	use Types::Standard -types;
	t->alias_type( Int => 'WholeNumber' );
	
	my $child = Int->where( '$_ > 42' );
	
	::ok( $child->is_strictly_a_type_of(Int) );
	::ok( $child->is_strictly_a_type_of('Int') );
	::ok( $child->is_strictly_a_type_of('WholeNumber') );
}

done_testing;
