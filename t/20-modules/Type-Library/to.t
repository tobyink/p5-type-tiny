=pod

=encoding utf-8

=head1 PURPOSE

Checks that the coercion functions exported by a type library work as expected.

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
use Test::Fatal qw(dies_ok);

use BiggerLib qw(:to);

is(
	to_BigInteger(8),
	18,
	'to_BigInteger converts a small integer OK'
);

is(
	to_BigInteger(17),
	17,
	'to_BigInteger leaves an existing BigInteger OK'
);

is(
	to_BigInteger(3.14),
	3.14,
	'to_BigInteger ignores something it cannot coerce'
);

dies_ok { to_Str [] } "no coercion for Str - should die";

done_testing;
