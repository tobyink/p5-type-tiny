=pod

=encoding utf-8

=head1 PURPOSE

Checks various newish Type::Registry method calls.

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
use Test::TypeTiny;
use Test::Fatal;

use Type::Registry qw( t );
use Types::Standard -types;

sub types_equal
{
	my ($a, $b) = map {
		ref($_)
			? $_
			: do { require Type::Parser; Type::Parser::_std_eval($_) }
	} @_[0, 1];
	my ($A, $B) = map { $_->inline_check('$X') } ($a, $b);
	my $msg = "$_[0] eq $_[1]";
	$msg = "$msg - $_[2]" if $_[2];
	@_ = ($A, $B, $msg);
	goto \&Test::More::is;
}

t->add_types( -Standard );

types_equal(
	t->make_class_type("Foo"),
	InstanceOf["Foo"],
	't->make_class_type',
);

types_equal(
	t->make_role_type("Foo"),
	ConsumerOf["Foo"],
	't->make_role_type',
);

types_equal(
	t->make_union(t->ArrayRef, t->Int),
	ArrayRef|Int,
	't->make_union',
);

types_equal(
	t->make_intersection(t->ArrayRef, t->Int),
	ArrayRef() &+ Int(),
	't->make_intersection',
);

my $type = t->foreign_lookup('Types::Common::Numeric::PositiveInt');
should_pass(420, $type);
should_fail(-42, $type);

t->add_type($type);
should_pass(420, t->PositiveInt);
should_fail(-42, t->PositiveInt);

t->add_type($type, 'PossyWossy1');
should_pass(420, t->PossyWossy1);
should_fail(-42, t->PossyWossy1);

t->add_type($type->create_child_type, 'PossyWossy2');
should_pass(420, t->PossyWossy2);
should_fail(-42, t->PossyWossy2);

like(
	exception { t->add_type($type->create_child_type) },
	qr/^Expected named type constraint; got anonymous type constraint/,
	'cannot add an anonymous type without giving it an alias',
);

done_testing;
