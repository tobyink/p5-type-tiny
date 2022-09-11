=pod

=encoding utf-8

=head1 PURPOSE

Tests warnings from Type::Params.

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

use Test::Requires 'Test::Warnings';
use Test::Warnings 'warning';

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

done_testing;
