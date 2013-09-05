=pod

=encoding utf-8

=head1 PURPOSE

Very basic Exporter::Tiny test.

Check that it allows us to import the functions named in C<< @EXPORT >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use lib qw( examples ../examples );

use Example::Exporter;

is fib(6), 8, 'Correctly imported "fib" from Example::Exporter';

ok !__PACKAGE__->can('embiggen'), 'Did not inadvertantly import "embiggen"';

done_testing;

