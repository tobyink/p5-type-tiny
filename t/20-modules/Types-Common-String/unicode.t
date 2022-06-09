=pod

=encoding utf-8

=head1 PURPOSE

Tests Unicode support for L<Types::Common::String>.

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
use utf8;
use Test::More;
use Test::TypeTiny;

use Types::Common::String -all;

should_pass('CAFÉ', UpperCaseStr, "CAFÉ is uppercase");
should_fail('CAFé', UpperCaseStr, "CAFé is not (entirely) uppercase");

should_fail('ŐħĤăĩ', UpperCaseStr, "----- not entirely uppercase");
should_fail('ŐħĤăĩ', LowerCaseStr, "----- not entirely lowercase");

should_pass('café', LowerCaseStr, "café is lowercase");
should_fail('cafÉ', LowerCaseStr, "cafÉ is not (entirely) lowercase");

should_pass('CAFÉ', UpperCaseSimpleStr, "CAFÉ is uppercase");
should_fail('CAFé', UpperCaseSimpleStr, "CAFé is not (entirely) uppercase");

should_pass('café', LowerCaseSimpleStr, "café is lowercase");
should_fail('cafÉ', LowerCaseSimpleStr, "cafÉ is not (entirely) lowercase");

done_testing;
