=pod

=encoding utf-8

=head1 PURPOSE

Check type constraint inlining works with L<Moose> in strange edge
cases where we need to inflate Type::Tiny constraints into full
L<Moose::Meta::TypeConstraint> objects.

=head1 DEPENDENCIES

Test is skipped if Moose 2.1210 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More 0.96;
use Test::Requires { 'Moose' => '2.1005' };

use Type::Tiny;

my $type1 = Type::Tiny->new;
my $type2 = $type1->create_child_type(
	constraint => sub { !!2 },
	inlined    => sub {
		my ($self, $var) = @_;
		$self->parent->inline_check($var) . " && !!2";
	},
);

like(
	$type2->inline_check('$XXX'),
	qr/\(\(?!!1\)? && !!2\)/,
	'$type2->inline_check'
);

like(
	$type2->moose_type->_inline_check('$XXX'),
	qr/\(\(?!!1\)? && !!2\)/,
	'$type2->moose_type->_inline_check'
);

done_testing;
