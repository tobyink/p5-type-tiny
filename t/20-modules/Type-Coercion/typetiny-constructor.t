=pod

=encoding utf-8

=head1 PURPOSE

Checks proper Type::Coercion objects are automatically created by the
Type::Tiny constructor.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use Type::Tiny;
use Types::Standard qw( Int Num Any );

subtest "coercion => ARRAY" => sub
{
	my $type = Type::Tiny->new(
		name      => 'Test',
		parent    => Int,
		coercion  => [ Num, sub { int($_) } ],
	);
	
	ok $type->has_coercion;
	is $type->coercion->type_coercion_map->[0], Num;
	is $type->coerce(3.2), 3;
};

subtest "coercion => CODE" => sub
{
	my $type = Type::Tiny->new(
		name      => 'Test',
		parent    => Int,
		coercion  => sub { int($_) },
	);
	
	ok $type->has_coercion;
	is $type->coercion->type_coercion_map->[0], Any;
	is $type->coerce(3.2), 3;
};

done_testing;
