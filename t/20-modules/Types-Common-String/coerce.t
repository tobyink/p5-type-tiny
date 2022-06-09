=pod

=encoding utf-8

=head1 PURPOSE

Tests coercions for L<Types::Common::String>.

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

This software is copyright (c) 2013-2014, 2017-2022 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Common::String qw(
	+LowerCaseSimpleStr
	+UpperCaseSimpleStr
	+LowerCaseStr
	+UpperCaseStr
	+NumericCode
);

is(to_UpperCaseSimpleStr('foo'), 'FOO', 'uppercase str' );
is(to_LowerCaseSimpleStr('BAR'), 'bar', 'lowercase str' );

is(to_UpperCaseStr('foo'), 'FOO', 'uppercase str' );
is(to_LowerCaseStr('BAR'), 'bar', 'lowercase str' );

is(to_NumericCode('4111-1111-1111-1111'), '4111111111111111', 'numeric code' );
is(to_NumericCode('+1 (800) 555-01-23'), '18005550123', 'numeric code' );

done_testing;
