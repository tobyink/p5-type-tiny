=pod

=encoding utf-8

=head1 PURPOSE

Check that Specio type constraints can be converted to Type::Tiny
with inlining support.

=head1 DEPENDENCIES

Test is skipped if Specio is not available.

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
use Test::Requires 'Specio';
use Specio::Library::Builtins;
use Types::TypeTiny 'to_TypeTiny';

my $Int = to_TypeTiny t('Int');

ok  $Int->check('4');
ok !$Int->check('4.1');
ok  $Int->can_be_inlined;

my $check_x = $Int->inline_check('$x');

ok do { my $x = '4';    eval $check_x };
ok do { my $x = '4.1'; !eval $check_x };

done_testing;
