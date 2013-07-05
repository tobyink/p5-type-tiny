=pod

=encoding utf-8

=head1 PURPOSE

Checks Moose type constraints, and L<MooseX::Types> type constraints are
picked up by C<dwim_type> from L<Type::Utils>.

=head1 DEPENDENCIES

Moose 2.0600 and MooseX::Types::Common::Numeric 0.001008;
skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "MooseX::Types::Common::Numeric" => "0.001008" };
use Test::Requires { "Moose" => "2.0600" };
use Test::TypeTiny;

use Type::Utils qw(dwim_type);

my $digit = dwim_type 'MooseX::Types::Common::Numeric::SingleDigit';

should_pass($_, $digit) for 1 .. 9;
should_fail($_, $digit) for 10, 11, -1, 'xyz', 'x', [], {}, undef;

my $digits = dwim_type 'ArrayRef[MooseX::Types::Common::Numeric::SingleDigit]';

should_pass([], $digits);
should_pass([qw/1 2 3/], $digits);
should_fail(2, $digits);
should_fail([qw/11 2 3/], $digits);
should_fail([qw/x 2 3/], $digits);

use Moose::Util::TypeConstraints qw(subtype as where);

subtype 'SingleSmallDigit',
	as MooseX::Types::Common::Numeric::SingleDigit(),
	where { $_ <= 5 };

my $smalldigit = dwim_type 'SingleSmallDigit';

should_pass($_, $smalldigit) for 1 .. 5;
should_fail($_, $smalldigit) for 6 .. 11, -1, 'xyz', 'x', [], {}, undef;

my $smalldigits = dwim_type 'ArrayRef[SingleSmallDigit]';

should_pass([], $smalldigits);
should_pass([qw/1 2 3/], $smalldigits);
should_fail(2, $smalldigits);
should_fail([qw/11 2 3/], $smalldigits);
should_fail([qw/x 2 3/], $smalldigits);
should_fail([qw/7 2 3/], $smalldigits);

done_testing;
