=pod

=encoding utf-8

=head1 PURPOSE

Checks that the assertion functions exported by a type library work as expected.

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
use Test::Fatal;

use BiggerLib qw( :assert );

ok assert_String("rats"), "assert_String works (value that should pass)";
like(
	exception { assert_String([]) },
	qr{^is not a string},
	"assert_String works (value that should fail)"
);

ok BiggerLib::assert_String("rats"), "BiggerLib::assert_String works (value that should pass)";
like(
	exception { BiggerLib::assert_String([]) },
	qr{^is not a string},
	"BiggerLib::assert_String works (value that should fail)"
);

ok assert_SmallInteger(5), "assert_SmallInteger works (value that should pass)";
like(
	exception { assert_SmallInteger([]) },
	qr{^ARRAY\(\w+\) is too big},
	"assert_SmallInteger works (value that should fail)"
);

done_testing;
