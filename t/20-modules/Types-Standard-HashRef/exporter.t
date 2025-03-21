=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::HashRef can export.

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
use Types::Standard::HashRef (
	IntHash => { type => Int },
	NumHash => { of => 'Num' },
);

is IntHash->name, "IntHash";
is NumHash->name, "NumHash";

ok is_IntHash { one => 1 };
ok is_NumHash { one => 1.1 };
ok !is_IntHash [ undef ];
ok !is_NumHash [ undef ];

require Type::Registry;
is( 'Type::Registry'->for_me->{'IntHash'}, IntHash );
is( 'Type::Registry'->for_me->{'NumHash'}, NumHash );

done_testing;
