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

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Common::Numeric qw(
	+PositiveNum +PositiveOrZeroNum
	+PositiveInt +PositiveOrZeroInt
	+NegativeNum +NegativeOrZeroNum
	+NegativeInt +NegativeOrZeroInt
	+SingleDigit
);

ok(!is_SingleDigit(100), 'SingleDigit 100');
ok(!is_SingleDigit(10), 'SingleDigit 10');
ok(is_SingleDigit(9), 'SingleDigit 9');
ok(is_SingleDigit(1), 'SingleDigit 1');
ok(is_SingleDigit(0), 'SingleDigit 0');
ok(is_SingleDigit(-1), 'SingleDigit -1');
ok(is_SingleDigit(-9), 'SingleDigit -9');
ok(!is_SingleDigit(-10), 'SingleDigit -10');


ok(!is_PositiveInt(-100), 'PositiveInt (-100)');
ok(!is_PositiveInt(0), 'PositiveInt (0)');
ok(!is_PositiveInt(100.885), 'PositiveInt (100.885)');
ok(is_PositiveInt(100), 'PositiveInt (100)');
ok(!is_PositiveNum(0), 'PositiveNum (0)');
ok(is_PositiveNum(100.885), 'PositiveNum (100.885)');
ok(!is_PositiveNum(-100.885), 'PositiveNum (-100.885)');
ok(is_PositiveNum(0.0000000001), 'PositiveNum (0.0000000001)');

ok(!is_PositiveOrZeroInt(-100), 'PositiveOrZeroInt (-100)');
ok(is_PositiveOrZeroInt(0), 'PositiveOrZeroInt (0)');
ok(!is_PositiveOrZeroInt(100.885), 'PositiveOrZeroInt (100.885)');
ok(is_PositiveOrZeroInt(100), 'PositiveOrZeroInt (100)');
ok(is_PositiveOrZeroNum(0), 'PositiveOrZeroNum (0)');
ok(is_PositiveOrZeroNum(100.885), 'PositiveOrZeroNum (100.885)');
ok(!is_PositiveOrZeroNum(-100.885), 'PositiveOrZeroNum (-100.885)');
ok(is_PositiveOrZeroNum(0.0000000001), 'PositiveOrZeroNum (0.0000000001)');

ok(!is_NegativeInt(100), 'NegativeInt (100)');
ok(!is_NegativeInt(-100.885), 'NegativeInt (-100.885)');
ok(is_NegativeInt(-100), 'NegativeInt (-100)');
ok(!is_NegativeInt(0), 'NegativeInt (0)');
ok(is_NegativeNum(-100.885), 'NegativeNum (-100.885)');
ok(!is_NegativeNum(100.885), 'NegativeNum (100.885)');
ok(!is_NegativeNum(0), 'NegativeNum (0)');
ok(is_NegativeNum(-0.0000000001), 'NegativeNum (-0.0000000001)');

ok(!is_NegativeOrZeroInt(100), 'NegativeOrZeroInt (100)');
ok(!is_NegativeOrZeroInt(-100.885), 'NegativeOrZeroInt (-100.885)');
ok(is_NegativeOrZeroInt(-100), 'NegativeOrZeroInt (-100)');
ok(is_NegativeOrZeroInt(0), 'NegativeOrZeroInt (0)');
ok(is_NegativeOrZeroNum(-100.885), 'NegativeOrZeroNum (-100.885)');
ok(!is_NegativeOrZeroNum(100.885), 'NegativeOrZeroNum (100.885)');
ok(is_NegativeOrZeroNum(0), 'NegativeOrZeroNum (0)');
ok(is_NegativeOrZeroNum(-0.0000000001), 'NegativeOrZeroNum (-0.0000000001)');

done_testing;
