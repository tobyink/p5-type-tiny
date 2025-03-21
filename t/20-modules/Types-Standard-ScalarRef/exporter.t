=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::ScalarRef can export.

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
use Types::Standard::ScalarRef (
	IntRef => { type => Int },
	NumRef => { of => 'Num' },
);

is IntRef->name, "IntRef";
is NumRef->name, "NumRef";

ok is_IntRef \1;
ok is_NumRef \1.1;
ok !is_IntRef \1.1;
ok !is_NumRef \"foo";

require Type::Registry;
is( 'Type::Registry'->for_me->{'IntRef'}, IntRef );
is( 'Type::Registry'->for_me->{'NumRef'}, NumRef );

done_testing;
