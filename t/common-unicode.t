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

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;

use Types::Common::String -all;

ok(  is_UpperCaseStr('CAFÉ'), q[CAFÉ is uppercase] );
ok( !is_UpperCaseStr('CAFé'), q[CAFé is not (entirely) uppercase] );

ok( !is_UpperCaseStr('ŐħĤăĩ'), q[----- not entirely uppercase] );
ok( !is_LowerCaseStr('ŐħĤăĩ'), q[----- not entirely lowercase] );

ok(  is_LowerCaseStr('café'), q[café is lowercase] );
ok( !is_LowerCaseStr('cafÉ'), q[cafÉ is not (entirely) lowercase] );

ok(  is_UpperCaseSimpleStr('CAFÉ'), q[CAFÉ is uppercase] );
ok( !is_UpperCaseSimpleStr('CAFé'), q[CAFé is not (entirely) uppercase] );

ok(  is_LowerCaseSimpleStr('café'), q[café is lowercase] );
ok( !is_LowerCaseSimpleStr('cafÉ'), q[cafÉ is not (entirely) lowercase] );

done_testing;
