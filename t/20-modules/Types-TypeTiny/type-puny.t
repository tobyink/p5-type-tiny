=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny works okay with Type::Puny, a clone of Type::Nano.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


use lib qw( ./lib ./t/lib ./inc );
use strict;
use warnings;

use Test::More;

use Test::Requires 'Type::Puny';
use Types::Standard;
use Types::TypeTiny 'to_TypeTiny';
use Test::Fatal;
use Test::TypeTiny;

my $conv = to_TypeTiny( Type::Puny::ArrayRef );

should_pass(
	[ 1 .. 3 ],
	$conv,
);

should_fail(
	'Hello world',
	$conv,
);

like(
	exception { $conv->(undef) },
	qr/ArrayRef/,
	'get_message worked',
);

my $t1 = Types::Standard::ArrayRef->of( Type::Puny::Int );

should_pass(
	[ 1 .. 3 ],
	$t1,
);

should_fail(
	{},
	$t1,
);

should_fail(
	[ 1 .. 3, undef ],
	$t1,
);

{
	package Type::Puny::PlusCoerce;
	our @ISA = 'Type::Puny';
	sub has_coercion { exists shift->{coercion} }
	sub coercion     {        shift->{coercion} }
	sub coerce       { local $_ = pop; shift->coercion->($_) }
}

my $Rounded = 'Type::Puny::PlusCoerce'->new(
	name       => 'Rounded',
	parent     => Type::Puny::Int,
	constraint => sub { 1 },
	coercion   => sub { int $_ },
);

my $RoundedTT = to_TypeTiny( $Rounded );

ok $RoundedTT->has_coercion, 'Type::Puny::PlusCoerce->has_coercion';
is $RoundedTT->coerce(4.1), 4, 'Type::Puny::PlusCoerce->coerce';

done_testing;