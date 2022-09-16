=pod

=encoding utf-8

=head1 PURPOSE

Tests that Type::Params v2 C<signature_for> delays signature compilation.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Types::Common -types;
use Type::Params -sigs;

my $compiled = 0;

my $MyStr = Str->create_child_type(
	name       => 'MyStr',
	constraint => sub { 1 },
	inlined    => sub {
		++$compiled;
		Str->inline_check( pop );
	},
);

signature_for xyz => ( pos => [ $MyStr ] );

sub xyz {
	my $got = shift;
	return scalar reverse $got;
}

is(
	$compiled,
	0,
	'type constraint has not been compiled yet',
);

is( xyz('foo'), 'oof', 'function worked' );

is(
	$compiled,
	1,
	'type constraint has been compiled',
);

is( xyz('bar'), 'rab', 'function worked' );

is(
	$compiled,
	1,
	'type constraint has not been re-compiled',
);

done_testing;
