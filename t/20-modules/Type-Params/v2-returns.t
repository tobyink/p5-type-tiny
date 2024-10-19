=pod

=encoding utf-8

=head1 PURPOSE

Check that Type::Params v2 supports return typrs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params -sigs;
use Types::Common -types;

subtest "Simple return type" => sub {
	signature_for test1 => (
		pos     => [ Num, Num ],
		returns => Int,
	);

	sub test1 {
		my ( $x, $y ) = @_;
		return $x + $y;
	}

	is( scalar( test1( 2, 3 ) ), 5, 'happy path, scalar context' );
	is_deeply( [ test1( 2, 3 ) ], [ 5 ], 'happy path, list context' );
	is( do { test1( 2, 3 ); 1 }, 1, 'happy path, void context' );

	ok(  exception { scalar( test1( 2.1, 3 ) ) }, 'bad path, scalar context' );
	ok(  exception { [ test1( 2.1, 3 ) ] }, 'bad path, list context' );
	ok( !exception { do { test1( 2.1, 3 ); 1 } }, 'bad path, void context' );
};

subtest "Non-inlinable return type" => sub {
	signature_for test2 => (
		pos     => [ Num, Num ],
		returns => Int->where(sub { 1 }),
	);

	sub test2 {
		my ( $x, $y ) = @_;
		return $x + $y;
	}

	is( scalar( test2( 2, 3 ) ), 5, 'happy path, scalar context' );
	is_deeply( [ test2( 2, 3 ) ], [ 5 ], 'happy path, list context' );
	is( do { test2( 2, 3 ); 1 }, 1, 'happy path, void context' );

	ok(  exception { scalar( test2( 2.1, 3 ) ) }, 'bad path, scalar context' );
	ok(  exception { [ test2( 2.1, 3 ) ] }, 'bad path, list context' );
	ok( !exception { do { test2( 2.1, 3 ); 1 } }, 'bad path, void context' );
};

subtest "Per-context return types" => sub {
	signature_for test3 => (
		pos            => [ Num ],
		returns_scalar => Int,
		returns_list   => HashRef[ Int ],
	);

	sub test3 {
		my ( $x ) = @_;
		wantarray ? ( foo => $x ) : $x;
	}

	is( scalar( test3( 5 ) ), 5, 'happy path, scalar context' );
	is_deeply( [ test3( 5 ) ], [ foo => 5 ], 'happy path, list context' );
	is( do { test3( 5 ); 1 }, 1, 'happy path, void context' );

	ok(  exception { scalar( test3( 5.1 ) ) }, 'bad path, scalar context' );
	ok(  exception { [ test3( 5.1 ) ] }, 'bad path, list context' );
	ok( !exception { do { test3( 5.1 ); 1 } }, 'bad path, void context' );
};

subtest "Multi + return types" => sub {
	my $T = signature_for test4 => (
		multi   => [ [Int], [Num] ],
		returns => Int,
	);
	
	sub test4 {
		shift;
	}

	ok( !exception { my $z = test4( 1   ) } );
	ok(  exception { my $z = test4( 1.1 ) } );
	ok( !exception { test4( 1.1 ); undef; } );
};

done_testing;
