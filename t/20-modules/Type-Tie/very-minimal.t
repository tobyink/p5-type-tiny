=pod

=encoding utf-8

=head1 PURPOSE

Test Type::Tie with a very minimal object, with only a C<check> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Tie;
use Scalar::Util qw( looks_like_number );

sub Local::TypeConstraint::check {
	my $coderef = shift;
	&$coderef;
};

my $Num = bless(
	sub { looks_like_number $_[0] },
	'Local::TypeConstraint',
);

ttie my($x), $Num, 0;

$x = 1;

is $x, 1;

like(
	exception { $x = 'Foo' },
	qr/^Value "Foo" does not meet type constraint/,
);

done_testing;
