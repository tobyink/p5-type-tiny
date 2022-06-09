=pod

=encoding utf-8

=head1 PURPOSE

Check for memory cycles.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=130823>.

=head1 AUTHOR

Toby Inkster <tobyink@cpan.org>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::Memory::Cycle';
use Test::Memory::Cycle;
use Types::Standard qw(Bool);

memory_cycle_ok(Bool, 'Bool has no cycles');

done_testing;
