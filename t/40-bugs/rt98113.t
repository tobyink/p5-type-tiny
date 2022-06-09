=pod

=encoding utf-8

=head1 PURPOSE

Test overload fallback

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=98113>.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Dagfinn Ilmari Mannsåker E<lt>ilmari@ilmari.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Dagfinn Ilmari Mannsåker

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use BiggerLib -types, -coercions;

is(
	exception { no warnings 'numeric'; BigInteger + 42 },
	undef,
	'Type::Tiny overload fallback works',
);

is(
	exception { BigInteger->coercion eq '1' },
	undef,
	'Type::Coercion overload fallback works',
);

done_testing;
