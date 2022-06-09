=pod

=encoding utf-8

=head1 PURPOSE

Ensure that the following works consistently on all supported Perls:

    HashRef[Int]|Undef, @extra_parameters

=head1 AUTHOR

Graham Knop E<lt>haarg@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Standard -all;

my $union = eval { Dict[ welp => HashRef[Int]|Undef, guff => ArrayRef[Int] ] };

SKIP: {
	ok $union or skip 'broken type', 6;
	ok $union->check({welp => {blorp => 1}, guff => [2]});
	ok $union->check({welp => undef, guff => [2]});
	ok $union->check({welp => {}, guff => []});
	ok !$union->check({welp => {}, guff => {}});
	ok !$union->check({welp => {blorp => 1}});
	ok !$union->check({guff => [2]});
}

done_testing;
