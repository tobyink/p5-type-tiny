=pod

=encoding utf-8

=head1 PURPOSE

Ensure that stringifying L<Error::TypeTiny> doesn't clobber C<< $@ >>.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/166>.

=head1 AUTHOR

Karen Etheridge L<https://github.com/karenetheridge>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard 'Str';
my $type = Str;
eval { $type->({}); };

like "### e string: '$@'\n", qr{did not pass type constraint};
like "### e string: '$@'\n", qr{did not pass type constraint};

done_testing;
