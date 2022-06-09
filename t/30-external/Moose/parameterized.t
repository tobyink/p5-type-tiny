=pod

=encoding utf-8

=head1 PURPOSE

Test that parameterizable Moose types are still parameterizable
when they are converted to Type::Tiny.

=head1 DEPENDENCIES

Test is skipped if Moose is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose::Util::TypeConstraints';
use Types::TypeTiny 'to_TypeTiny';
use Test::TypeTiny;

## We want to prevent Types::TypeTiny from noticing we've loaded a
## core type, because then it will just steal from Types::Standard.
## and bypass making a new type constraint.
##
sub Types::Standard::get_type { return() }
$INC{'Types/Standard.pm'} = 1;

my $mt_ArrayRef = Moose::Util::TypeConstraints::find_type_constraint('ArrayRef');
my $mt_Int      = Moose::Util::TypeConstraints::find_type_constraint('Int');
my $tt_ArrayRef = to_TypeTiny($mt_ArrayRef);
my $tt_Int      = to_TypeTiny($mt_Int);

ok $tt_ArrayRef->is_parameterizable;

my $tt_ArrayRef_of_Int = $tt_ArrayRef->of($tt_Int);

should_pass [qw/1 2 3/], $tt_ArrayRef_of_Int;
should_fail [qw/a b c/], $tt_ArrayRef_of_Int;

done_testing;
