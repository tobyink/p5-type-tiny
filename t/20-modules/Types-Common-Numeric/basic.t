=pod

=encoding utf-8

=head1 PURPOSE

Tests constraints for L<Types::Common::Numeric>.

These tests are based on tests from L<MooseX::Types::Common>.

=head1 AUTHORS

=over 4
 
=item *
 
Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)
 
=item *
 
K. James Cheetham <jamie@shadowcatsystems.co.uk>
 
=item *
 
Guillermo Roditi <groditi@gmail.com>
 
=back

Test cases ported to L<Test::TypeTiny> by Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::TypeTiny;

use Types::Common::Numeric -all;

should_fail(100, SingleDigit, "SingleDigit 100");
should_fail(10, SingleDigit, "SingleDigit 10");
should_pass(9, SingleDigit, "SingleDigit 9");
should_pass(1, SingleDigit, "SingleDigit 1");
should_pass(0, SingleDigit, "SingleDigit 0");
should_pass(-1, SingleDigit, "SingleDigit -1");
should_pass(-9, SingleDigit, "SingleDigit -9");
should_fail(-10, SingleDigit, "SingleDigit -10");


should_fail(-100, PositiveInt, "PositiveInt (-100)");
should_fail(0, PositiveInt, "PositiveInt (0)");
should_fail(100.885, PositiveInt, "PositiveInt (100.885)");
should_pass(100, PositiveInt, "PositiveInt (100)");
should_fail(0, PositiveNum, "PositiveNum (0)");
should_pass(100.885, PositiveNum, "PositiveNum (100.885)");
should_fail(-100.885, PositiveNum, "PositiveNum (-100.885)");
should_pass(0.0000000001, PositiveNum, "PositiveNum (0.0000000001)");

should_fail(-100, PositiveOrZeroInt, "PositiveOrZeroInt (-100)");
should_pass(0, PositiveOrZeroInt, "PositiveOrZeroInt (0)");
should_fail(100.885, PositiveOrZeroInt, "PositiveOrZeroInt (100.885)");
should_pass(100, PositiveOrZeroInt, "PositiveOrZeroInt (100)");
should_pass(0, PositiveOrZeroNum, "PositiveOrZeroNum (0)");
should_pass(100.885, PositiveOrZeroNum, "PositiveOrZeroNum (100.885)");
should_fail(-100.885, PositiveOrZeroNum, "PositiveOrZeroNum (-100.885)");
should_pass(0.0000000001, PositiveOrZeroNum, "PositiveOrZeroNum (0.0000000001)");

should_fail(100, NegativeInt, "NegativeInt (100)");
should_fail(-100.885, NegativeInt, "NegativeInt (-100.885)");
should_pass(-100, NegativeInt, "NegativeInt (-100)");
should_fail(0, NegativeInt, "NegativeInt (0)");
should_pass(-100.885, NegativeNum, "NegativeNum (-100.885)");
should_fail(100.885, NegativeNum, "NegativeNum (100.885)");
should_fail(0, NegativeNum, "NegativeNum (0)");
should_pass(-0.0000000001, NegativeNum, "NegativeNum (-0.0000000001)");

should_fail(100, NegativeOrZeroInt, "NegativeOrZeroInt (100)");
should_fail(-100.885, NegativeOrZeroInt, "NegativeOrZeroInt (-100.885)");
should_pass(-100, NegativeOrZeroInt, "NegativeOrZeroInt (-100)");
should_pass(0, NegativeOrZeroInt, "NegativeOrZeroInt (0)");
should_pass(-100.885, NegativeOrZeroNum, "NegativeOrZeroNum (-100.885)");
should_fail(100.885, NegativeOrZeroNum, "NegativeOrZeroNum (100.885)");
should_pass(0, NegativeOrZeroNum, "NegativeOrZeroNum (0)");
should_pass(-0.0000000001, NegativeOrZeroNum, "NegativeOrZeroNum (-0.0000000001)");

done_testing;
