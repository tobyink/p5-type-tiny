=pod

=encoding utf-8

=head1 PURPOSE

Named parameter tests for modern Type::Params v2 API.

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
use Test::Fatal;
use Test::TypeTiny;

use Types::Common -all;

our @ARGS;

signature_for [ qw/ get_list get_arrayref get_hashref / ] => (
	named => [
		foo => Int, { alias => 'fool' },
		bar => Optional[Int],
	],
);

sub get_list {
	shift->__TO_LIST__( @ARGS );
}

subtest '__TO_LIST__' => sub {
	
	is_deeply(
		[ get_list( foo => 66, bar => 99 ) ],
		[ 66, 99 ],
	);
	
	local @ARGS = ( [ qw/ foo foo bar foo / ] );
	is_deeply(
		[ get_list( foo => 66, bar => 99 ) ],
		[ 66, 66, 99, 66 ],
	);

	local @ARGS = ( [ qw/ foo / ] );
	is_deeply(
		[ get_list( foo => 66, bar => 99 ) ],
		[ 66 ],
	);
	
	local @ARGS = ( [ qw/ bar fool / ] );
	is_deeply(
		[ get_list( foo => 66, bar => 99 ) ],
		[ 99, 66 ],
	);
	
	local @ARGS = ( [ qw/ BAR / ] );
	isnt(
		exception { get_list( foo => 66, bar => 99 ) },
		undef,
	);
};

sub get_arrayref {
	shift->__TO_ARRAYREF__( @ARGS );
}

subtest '__TO_ARRAYREF__' => sub {
	
	is_deeply(
		get_arrayref( foo => 66, bar => 99 ),
		[ 66, 99 ],
	);
	
	local @ARGS = ( [ qw/ foo foo bar foo / ] );
	is_deeply(
		get_arrayref( foo => 66, bar => 99 ),
		[ 66, 66, 99, 66 ],
	);

	local @ARGS = ( [ qw/ foo / ] );
	is_deeply(
		get_arrayref( foo => 66, bar => 99 ),
		[ 66 ],
	);
	
	local @ARGS = ( [ qw/ bar fool / ] );
	is_deeply(
		get_arrayref( foo => 66, bar => 99 ),
		[ 99, 66 ],
	);
	
	local @ARGS = ( [ qw/ BAR / ] );
	isnt(
		exception { get_arrayref( foo => 66, bar => 99 ) },
		undef,
	);
};

sub get_hashref {
	shift->__TO_HASHREF__( @ARGS );
}

subtest '__TO_HASHREF__' => sub {
	
	is_deeply(
		get_hashref( foo => 66, bar => 99 ),
		{ foo => 66, bar => 99 },
	);
	
	local @ARGS = ( [ qw/ foo foo bar foo / ] );
	is_deeply(
		get_hashref( foo => 66, bar => 99 ),
		{ foo => 66, bar => 99 },
	);

	local @ARGS = ( [ qw/ foo / ] );
	is_deeply(
		get_hashref( foo => 66, bar => 99 ),
		{ foo => 66 },
	);
	
	local @ARGS = ( [ qw/ bar fool / ] );
	is_deeply(
		get_hashref( foo => 66, bar => 99 ),
		{ fool => 66, bar => 99 },
	);
	
	local @ARGS = ( [ qw/ bar fool foo / ] );
	is_deeply(
		get_hashref( foo => 66, bar => 99 ),
		{ foo => 66, fool => 66, bar => 99 },
	);
	
	local @ARGS = ( [ qw/ BAR / ] );
	isnt(
		exception { get_hashref( foo => 66, bar => 99 ) },
		undef,
	);
};

done_testing;
