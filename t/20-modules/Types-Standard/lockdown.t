=pod

=head1 PURPOSE

OK, we need to bite the bullet and lock down coercions on core type
constraints and parameterized type constraints.

=head1 SEE ALSO

L<RT 97516|https://rt.cpan.org/Public/Bug/Display.html?id=97516>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Types::Standard -types;
use Types::Common::Numeric -types;

my $frozen = qr/\AAttempt to add coercion code to a Type::Coercion/;

like(
	exception {
		Str->coercion->add_type_coercions(ArrayRef, sub { "@$_" });
	},
	$frozen,
	'Types::Standard core types are frozen',
);

like(
	exception {
		PositiveInt->coercion->add_type_coercions(NegativeInt, sub { -$_ });
	},
	$frozen,
	'Types::Common types are frozen',
);

like(
	exception {
		InstanceOf->of("Foo")->coercion->add_type_coercions(HashRef, sub { bless $_, "Foo" });
	},
	$frozen,
	'Parameterized types are frozen',
);

done_testing;
