=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Parser can pick up MooseX::Types type constraints.

=head1 DEPENDENCIES

Requires L<Moose> 2.0201 and L<MooseX::Types::Common> 0.001004;
skipped otherwise.

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

use Type::Parser qw(_std_eval parse);
use Types::Standard qw(-types slurpy);
use Type::Utils;

my $type = _std_eval("ArrayRef[MooseX::Types::Common::Numeric::PositiveInt]");

should_pass([1,2,3], $type);
should_pass([], $type);
should_fail([1,-2,3], $type);

done_testing;
