=pod

=encoding utf-8

=head1 PURPOSE

Tests errors thrown by L<Type::Library>.

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
use Test::Fatal;

use Type::Library -base;
use Type::Tiny;

my $e1 = exception {
	my $m = __PACKAGE__->meta;
	$m->add_type(name => 'Foo');
	$m->add_type(name => 'Foo');
};

like(
	$e1,
	qr/^Type Foo already exists in this library/,
	'cannot add same type constraint twice',
);

my $e2 = exception {
	my $m = __PACKAGE__->meta;
	$m->add_type(constraint => sub { 0 });
};

like(
	$e2,
	qr/^Cannot add anonymous type to a library/,
	'cannot add an anonymous type constraint to a library',
);

my $e3 = exception {
	my $m = __PACKAGE__->meta;
	$m->add_coercion(name => 'Foo');
};

like(
	$e3,
	qr/^Coercion Foo conflicts with type of same name/,
	'cannot add a coercion with same name as a constraint',
);

done_testing;
