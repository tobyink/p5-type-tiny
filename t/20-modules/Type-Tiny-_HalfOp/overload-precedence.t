=pod

=encoding utf-8

=head1 PURPOSE

Ensure that the following works consistently on all supported Perls:

   ArrayRef[Int] | HashRef[Int]

=head1 AUTHOR

Graham Knop E<lt>haarg@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Standard -all;

my $union = eval { ArrayRef[Int] | HashRef[Int] };

SKIP: {
	ok $union or skip 'broken type', 6;
	ok $union->check({welp => 1});
	ok !$union->check({welp => 1.4});
	ok !$union->check({welp => "guff"});
	ok $union->check([1]);
	ok !$union->check([1.4]);
	ok !$union->check(["guff"]);
}

done_testing;
