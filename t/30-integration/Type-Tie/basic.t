=pod

=encoding utf-8

=head1 PURPOSE

Test that this sort of thing works:

   tie my $var, Int;

=head1 DEPENDENCIES

Requires L<Type::Tie>; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Test::Requires { 'Type::Tie' => '0.008' };
use Types::Standard qw( ArrayRef Int );
use Test::Fatal;

subtest "tied scalar" => sub
{
	tie my($int), Int;
	
	is(
		exception { $int = 42 },
		undef,
	);
	
	like(
		exception { $int = 4.2 },
		qr/^Value "4.2" did not pass type constraint/,
	);
	
	is($int, 42);
	
	done_testing;
};

subtest "tied array" => sub
{
	tie my(@ints), Int;
	
	is(
		exception {
			$ints[0] = 1;
			push @ints, 2;
			unshift @ints, 0;
		},
		undef,
	);
	
	like(
		exception { $ints[3] = 3.5 },
		qr/^Value "3.5" did not pass type constraint/,
	);
	
	is_deeply(
		\@ints,
		[ 0..2 ],
	);
	
	done_testing;
};

subtest "tied hash" => sub
{
	tie my(%ints), Int;
	
	is(
		exception {
			$ints{one} = 1;
			$ints{two} = 2;
		},
		undef,
	);
	
	like(
		exception { $ints{three} = 3.5 },
		qr/^Value "3.5" did not pass type constraint/,
	);
	
	is_deeply(
		\%ints,
		{ one => 1, two => 2 },
	);
	
	done_testing;
};

done_testing;
