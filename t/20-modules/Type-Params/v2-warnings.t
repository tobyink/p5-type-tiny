=pod

=encoding utf-8

=head1 PURPOSE

Tests warnings from Type::Params.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Test::Requires 'Test::Warnings';
use Test::Warnings 'warning', 'warnings';

use Types::Common -sigs, -types;

{
	my $sig;
	my $w = warning {
		$sig = signature(
			package    => __PACKAGE__,
			subname    => 'test',
			positional => [
				ArrayRef,         { default => sub { [ 1 .. 4 ] } },
				Slurpy[ArrayRef], { default => sub { [ 1 .. 4 ] } },
			],
		);
	};
	
	like $w, qr/default for the slurpy parameter will be ignored/i, 'correct warning';
	is ref($sig), 'CODE', 'compilation succeeded';
	
	is_deeply(
		[ $sig->( [ 'a' .. 'z' ] ) ],
		[ [ 'a' .. 'z' ], [] ],
		'correct signature behaviour',
	);
}

{
	my $sig;
	my @w = warnings {
		$sig = signature(
			package    => __PACKAGE__,
			subname    => 'test2',
			multi      => [
				{
					positional => [
						ArrayRef,
						ArrayRef, { default => sub { [ 1 .. 4 ] }, bad1 => 1 },
					],
					bad2 => 2,
				},
				{
					named => [
						foo => ArrayRef,
						bar => ArrayRef,
					],
					bad3 => 3,
				},
				{
					named => [
						Foo => ArrayRef,
						Bar => ArrayRef,
					],
				},
			],
			bad4 => 4,
		);
	};
	
	# No guarantees about what order they happen in!
	@w = sort @w;
	
	ok @w == 5 or diag explain( \@w );
	
	like $w[0], qr/^Warning: unrecognized parameter option: bad1, continuing anyway/, 'warning for parameter';
	like $w[1], qr/^Warning: unrecognized signature option: bad4, continuing anyway/, 'warning for outer signature';
	like $w[2], qr/^Warning: unrecognized signature option: bad4, continuing anyway/, 'warning for third nested signature';
	like $w[3], qr/^Warning: unrecognized signature options: bad2 and bad4, continuing anyway/, 'warning for first nested signature';
	like $w[4], qr/^Warning: unrecognized signature options: bad3 and bad4, continuing anyway/, 'warning for second nested signature';
}

done_testing;
