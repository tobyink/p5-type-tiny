=pod

=encoding utf-8

=head1 PURPOSE

Test that Enum types containing hyphens work.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=129729>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;

use Types::Standard qw[ Bool Enum ];

my $x = Bool | Enum [ 'start-end', 'end' ];

should_pass 1, $x;
should_pass 0, $x;
should_fail 2, $x;
should_pass 'end', $x;
should_fail 'bend', $x;
should_fail 'start', $x;
should_fail 'start-', $x;
should_fail '-end', $x;
should_pass 'start-end', $x;

done_testing;
