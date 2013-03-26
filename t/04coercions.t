=pod

=encoding utf-8

=head1 PURPOSE

Checks that the coercion functions exported by a type library work as expected.

B<< Not yet implemented! >>

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More skip_all => "not implemeted yet; tests not even written yet!";
use Test::Fatal;

use BiggerLib qw(:to);

done_testing;