=pod

=encoding utf-8

=head1 PURPOSE

Test initializing tied variables.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/143>.

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Types::Common -types;

use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings ':all';

{
	tie my $x, Int, 143;
	is $x, 143;
}

{
	tie my @x, Int, 1 .. 3;
	is_deeply \@x, [ 1 .. 3 ];
}

{
	tie my %x, Int, foo => 666, bar => 999;
	is_deeply \%x, { foo => 666, bar => 999 };
}

{
	tie my $x, Int;
	is $x, 0;
}

done_testing;
