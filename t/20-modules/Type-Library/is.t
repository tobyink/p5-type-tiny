=pod

=encoding utf-8

=head1 PURPOSE

Checks that the check functions exported by a type library work as expected.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

use BiggerLib qw( :is );

ok  is_String("rats"),   "is_String works (value that should pass)";
ok !is_String([]),       "is_String works (value that should fail)";
ok  is_Number(5.5),      "is_Number works (value that should pass)";
ok !is_Number("rats"),   "is_Number works (value that should fail)";
ok  is_Integer(5),       "is_Integer works (value that should pass)";
ok !is_Integer(5.5),     "is_Integer works (value that should fail)";
ok  is_SmallInteger(5),  "is_SmallInteger works (value that should pass)";
ok !is_SmallInteger(12), "is_SmallInteger works (value that should fail)";

done_testing;
