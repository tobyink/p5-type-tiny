=pod

=encoding utf-8

=head1 PURPOSE

Check renaming imported functions.

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

use Example::Exporter
	embiggen => {},
	embiggen => { -suffix => '_by_2',  amount => 2 },
	embiggen => { -suffix => '_by_42', amount => 42 };

is embiggen(10), 11, 'embiggen';
is embiggen_by_2(10), 12, 'embiggen_by_2';
is embiggen_by_42(10), 52, 'embiggen_by_42';

is prototype(\&embiggen), '$', 'correct prototype';

done_testing;

