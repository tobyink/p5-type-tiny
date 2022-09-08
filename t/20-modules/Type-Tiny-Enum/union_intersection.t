=pod

=encoding utf-8

=head1 PURPOSE

Checks enums form natural unions and intersections.

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

use Types::Standard qw( Enum );

my $foo = Enum[ 1, 2, 3 ];
my $bar = Enum[ 1, 4, 5 ];

isa_ok(
	( my $foo_union_bar = $foo | $bar ),
	'Type::Tiny::Enum',
	'$foo_union_bar',
);

is_deeply(
	$foo_union_bar->unique_values,
	[ 1 .. 5 ],
	'$foo_union_bar->unique_values',
);

isa_ok(
	( my $foo_intersect_bar = $foo & $bar ),
	'Type::Tiny::Enum',
	'$foo_intersect_bar',
);

is_deeply(
	$foo_intersect_bar->unique_values,
	[ 1 ],
	'$foo_intersect_bar->unique_values',
);

done_testing;