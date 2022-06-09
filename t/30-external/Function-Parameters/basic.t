=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Function::Parameters>.

=head1 DEPENDENCIES

Requires Function::Parameters 1.0103, and either Moo 1.000000
or Moose 2.0000; skipped otherwise.

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
use Test::Requires { "Function::Parameters" => "1.0103" };
use Test::Fatal;

BEGIN {
	eval 'use Moo 1.000000; 1'
	or eval 'use Moose 2.0000; 1'
	or plan skip_all => "this test requires Moo 1.000000 or Moose 2.0000";
};

BEGIN { plan skip_all => 'Devel::Cover'  if $INC{'Devel/Cover.pm'} };

use Types::Standard -types;
use Function::Parameters qw(:strict);

fun foo ((Int) $x)
{
	return $x;
}

is(
	foo(4),
	4,
	'foo(4) works',
);

isnt(
	exception { foo(4.1) },
	undef,
	'foo(4.1) throws',
);

my $info = Function::Parameters::info(\&foo);
my ($x)  = $info->positional_required;
is($x->name, '$x', '$x->name');
ok($x->type == Int, '$x->type');

done_testing;
