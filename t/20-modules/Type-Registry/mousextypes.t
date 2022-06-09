=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry works with MouseX::Types.

=head1 DEPENDENCIES

Requires L<MouseX::Types::Common> 0.001000; skipped otherwise.

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
use Test::Requires { 'MouseX::Types::Common' => '0.001000' };
use Test::TypeTiny;
use Test::Fatal;

use Type::Registry 't';

t->add_types(-Standard);

my $nestr = t->lookup('ArrayRef[MouseX::Types::Common::String::NonEmptyStr]');
should_pass([], $nestr);
should_pass(['FOO', 'BAR'], $nestr);
should_fail(['FOO', ''], $nestr);

t->add_types('MouseX::Types::Common::Numeric');

should_pass(8, t->SingleDigit);
should_pass(9, t->SingleDigit);
should_fail(10, t->SingleDigit);
should_pass(10, t->PositiveInt);

done_testing;
