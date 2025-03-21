=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::CycleTuple can export.

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
use Types::Standard::CycleTuple (
	IntAndStr1 => { of => [ Int, Str ] },
	IntAndStr2 => { of => [ 'Int', 'Str' ] },
);

is IntAndStr1->name, "IntAndStr1";
is IntAndStr2->name, "IntAndStr2";

ok is_IntAndStr1 [ 1 => 'one', 2 => 'two' ];
ok is_IntAndStr2 [ 1 => 'one', 2 => 'two' ];
ok !is_IntAndStr1 [ one => 1 ];
ok !is_IntAndStr2 [ two => 2 ];

require Type::Registry;
is( 'Type::Registry'->for_me->{'IntAndStr1'}, IntAndStr1 );
is( 'Type::Registry'->for_me->{'IntAndStr2'}, IntAndStr2 );

done_testing;
