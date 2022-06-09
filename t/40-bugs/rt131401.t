=pod

=encoding utf-8

=head1 PURPOSE

Make sure that L<Type::Tiny::Class> loads L<Type::Tiny> early enough for
bareword constants to be okay.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=131401>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';
use Test::More tests => 1;

use Type::Tiny::Class;

ok 1;

