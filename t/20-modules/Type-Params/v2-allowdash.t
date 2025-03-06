=pod

=encoding utf-8

=head1 PURPOSE

Test allow_dash option for Type::Params.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Types::Standard qw( Int );
use Type::Params qw( signature_for );

signature_for test1 => (
	allow_dash => 0,
	named  => [
		foo => Int,
		bar => Int,
	],
);

sub test1 {
	my $args = shift;
	return $args->foo + $args->bar;
}

is test1(  foo => 1,  bar => 2 ), 3;
ok exception { test1( -foo => 1,  bar => 2 ) };
ok exception { test1(  foo => 1, -bar => 2 ) };
ok exception { test1( -foo => 1, -bar => 2 ) };

signature_for test2 => (
	allow_dash => 1,
	named  => [
		foo => Int,
		bar => Int,
	],
);

sub test2 {
	my $args = shift;
	return $args->foo + $args->bar;
}

is test2(  foo => 1,  bar => 2 ), 3;
is test2( -foo => 1,  bar => 2 ), 3;
is test2(  foo => 1, -bar => 2 ), 3;
is test2( -foo => 1, -bar => 2 ), 3;

signature_for test3 => (
	allow_dash => 1,
	named  => [
		foo => Int,
		bar => Int, { alias => 'baz' },
	],
);

sub test3 {
	my $args = shift;
	return $args->foo + $args->bar;
}

is test3(  foo => 1,  bar => 2 ), 3;
is test3( -foo => 1,  bar => 2 ), 3;
is test3(  foo => 1, -bar => 2 ), 3;
is test3( -foo => 1, -bar => 2 ), 3;
is test3(  foo => 1,  baz => 2 ), 3;
is test3( -foo => 1,  baz => 2 ), 3;
is test3(  foo => 1, -baz => 2 ), 3;
is test3( -foo => 1, -baz => 2 ), 3;

signature_for test4 => (
	allow_dash => 1,
	named  => [
		foo => Int,
		bar => Int, { allow_dash => 0 },
	],
);

sub test4 {
	my $args = shift;
	return $args->foo + $args->bar;
}

is test4(  foo => 1,  bar => 2 ), 3;
is test4( -foo => 1,  bar => 2 ), 3;
ok exception { test4(  foo => 1, -bar => 2 ) };
ok exception { test4( -foo => 1, -bar => 2 ) };

done_testing;
