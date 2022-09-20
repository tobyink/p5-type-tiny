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

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard qw( ArrayRef Int );
use Test::Fatal;

subtest "tied scalar" => sub
{
	tie my($int), Int;
	
	is(
		exception { $int = 42 },
		undef,
	);
	
	isnt(
		exception { $int = 4.2 },
		undef,
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
	
	isnt(
		exception { $ints[3] = 3.5 },
		undef,
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
	
	isnt(
		exception { $ints{three} = 3.5 },
		undef,
	);
	
	is_deeply(
		\%ints,
		{ one => 1, two => 2 },
	);
	
	done_testing;
};

done_testing;
