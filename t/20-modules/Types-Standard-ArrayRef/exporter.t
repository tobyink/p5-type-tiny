=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::ArrayRef can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard -types;
use Types::Standard::ArrayRef (
	Ints => { type => Int },
	Nums => { of => 'Num' },
);

is Ints->name, "Ints";
is Nums->name, "Nums";

ok is_Ints [ 1 .. 5 ];
ok is_Nums [ 1 .. 5 ];
ok !is_Ints [ undef ];
ok !is_Nums [ undef ];

require Type::Registry;
is( 'Type::Registry'->for_me->{'Ints'}, Ints );
is( 'Type::Registry'->for_me->{'Nums'}, Nums );

use Types::Standard::ArrayRef TwoInts => {
	of    => Int->where( q{ $_ > 0 } ),
	where => q{ @$_ == 2 },
};

ok is_TwoInts [ 1, 5 ];
ok !is_TwoInts [ 1 .. 5 ];
ok !is_TwoInts [ -1, 0 ];

done_testing;
