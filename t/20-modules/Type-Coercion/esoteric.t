=pod

=encoding utf-8

=head1 PURPOSE

Checks various undocumented Type::Coercion methods.

The fact that these are tested here should not be construed to mean tht
they are any any way a stable, supported part of the Type::Coercion API.

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
use Test::TypeTiny;

use Type::Coercion;
use Types::Standard -types;

my $type = Int->create_child_type;
$type->coercion->add_type_coercions( Num, q[int($_)] );

like(
	exception { $type->coercion->meta },
	qr/^Not really a Moose::Meta::TypeCoercion/,
	'$type->coercion->meta',
);

$type->coercion->_compiled_type_coercion(
	Type::Coercion->new(
		type_coercion_map => [ ArrayRef, q[666] ],
	),
);

$type->coercion->_compiled_type_coercion(
	sub { 999 },
);

is($type->coerce(3.1), 3, '$type->coercion->add_type_coercions(TYPE, STR)');
is($type->coerce([]), 666, '$type->coercion->_compiled_type_coercion(OBJECT)');
is($type->coerce(undef), 999, '$type->coercion->_compiled_type_coercion(CODE)');

my $J = Types::Standard::Join;
is("$J", 'Join');
like($J->_stringify_no_magic, qr/^Type::Coercion=HASH\(0x[0-9a-f]+\)$/i);

done_testing;
