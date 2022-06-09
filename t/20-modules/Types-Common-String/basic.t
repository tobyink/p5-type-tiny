=pod

=encoding utf-8

=head1 PURPOSE

Tests constraints for L<Types::Common::String>.

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

use Types::Common::String -all;

should_pass('', SimpleStr, "SimpleStr");
should_pass('a string', SimpleStr, "SimpleStr 2");
should_fail("another\nstring", SimpleStr, "SimpleStr 3");
should_fail(join('', ("long string" x 25)), SimpleStr, "SimpleStr 4");

should_fail('', NonEmptyStr, "NonEmptyStr");
should_pass('a string', NonEmptyStr, "NonEmptyStr 2");
should_pass("another string", NonEmptyStr, "NonEmptyStr 3");
should_pass(join('', ("long string" x 25)), NonEmptyStr, "NonEmptyStr 4");

should_pass('good str', NonEmptySimpleStr, "NonEmptySimplrStr");
should_fail('', NonEmptySimpleStr, "NonEmptyStr 2");

should_fail('no', Password, "Password");
should_pass('okay', Password, "Password 2");

should_fail('notokay', StrongPassword, "StrongPassword");
should_pass('83773r_ch01c3', StrongPassword, "StrongPassword 2");

should_fail('NOTOK', LowerCaseSimpleStr, "LowerCaseSimpleStr");
should_pass('ok', LowerCaseSimpleStr, "LowerCaseSimpleStr 2");
should_fail('NOTOK_123`"', LowerCaseSimpleStr, "LowerCaseSimpleStr 3");
should_pass('ok_123`"', LowerCaseSimpleStr, "LowerCaseSimpleStr 4");

should_fail('notok', UpperCaseSimpleStr, "UpperCaseSimpleStr");
should_pass('OK', UpperCaseSimpleStr, "UpperCaseSimpleStr 2");
should_fail('notok_123`"', UpperCaseSimpleStr, "UpperCaseSimpleStr 3");
should_pass('OK_123`"', UpperCaseSimpleStr, "UpperCaseSimpleStr 4");

should_fail('NOTOK', LowerCaseStr, "LowerCaseStr");
should_pass("ok\nok", LowerCaseStr, "LowerCaseStr 2");
should_fail('NOTOK_123`"', LowerCaseStr, "LowerCaseStr 3");
should_pass("ok\n_123`'", LowerCaseStr, "LowerCaseStr 4");

should_fail('notok', UpperCaseStr, "UpperCaseStr");
should_pass("OK\nOK", UpperCaseStr, "UpperCaseStr 2");
should_fail('notok_123`"', UpperCaseStr, "UpperCaseStr 3");
should_pass("OK\n_123`'", UpperCaseStr, "UpperCaseStr 4");

should_pass('032', NumericCode, "NumericCode lives");
should_fail('abc', NumericCode, "NumericCode dies");
should_fail('x18', NumericCode, "mixed NumericCode dies");

done_testing;
