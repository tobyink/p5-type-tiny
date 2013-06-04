=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Function::Parameters>.

=head1 DEPENDENCIES

Test is skipped if Function::Parameters 1.0101 or Moose 2.0000 is
not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { "Function::Parameters" => "1.0101" };
use Test::Requires { "Moose"                => "2.0000" };
use Test::Fatal;

use Types::Standard -types;
use Function::Parameters qw(:strict);
use Moose ();

fun foo ((Int) $x)
{
	return $x;
}

is(
	foo(4),
	4,
	'foo(4) works',
);

like(
	exception { foo(4.1) },
	qr{^In fun foo: parameter 1 \(\$x\): Value "4\.1" did not pass type constraint "Int"},
	'foo(4.1) throws',
);

done_testing;
