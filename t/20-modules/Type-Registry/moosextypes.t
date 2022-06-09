=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry works with MooseX::Types.

=head1 DEPENDENCIES

Requires L<Moose> 2.0201 and L<MooseX::Types::Common> 0.001004; 
kipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { 'Moose' => '2.0201' };
use Test::Requires { 'MooseX::Types::Common' => '0.001004' };
use Test::TypeTiny;
use Test::Fatal;

use Type::Registry 't';

t->add_types(-Standard);

my $ucstrs = t->lookup('ArrayRef[MooseX::Types::Common::String::UpperCaseStr]');
should_pass([], $ucstrs);
should_pass(['FOO', 'BAR'], $ucstrs);
should_fail(['FOO', 'Bar'], $ucstrs);

t->add_types('MooseX::Types::Common::Numeric');

should_pass(8, t->SingleDigit);
should_pass(9, t->SingleDigit);
should_fail(10, t->SingleDigit);
should_pass(10, t->PositiveInt);

done_testing;
