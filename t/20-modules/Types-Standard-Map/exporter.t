=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::Map can export.

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
use Types::Standard::Map (
	IntMap1 => { keys => Int, values => Str },
	IntMap2 => { of => [ 'Int', 'Str' ] },
);

is IntMap1->name, "IntMap1";
is IntMap2->name, "IntMap2";

ok is_IntMap1 { 1 => 'one' };
ok is_IntMap2 { 2 => 'two' };
ok !is_IntMap1 { one => 1 };
ok !is_IntMap2 { two => 2 };

require Type::Registry;
is( 'Type::Registry'->for_me->{'IntMap1'}, IntMap1 );
is( 'Type::Registry'->for_me->{'IntMap2'}, IntMap2 );

done_testing;
