=pod

=encoding utf-8

=head1 PURPOSE

Tests warnings raised by L<Type::Utils>.

=head1 DEPENDENCIES

Requires Perl 5.14 and L<Test::Warnings>; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires '5.014';
use Test::Requires { 'Test::Warnings' => 0.005 }; #warnings added in this version
use Test::Warnings qw( :no_end_test warnings );

use Type::Library -base, -declare => qw/WholeNumber/;
use Type::Utils -all;
use Types::Standard qw/Int/;

my @warnings = warnings {
	declare WholeNumber as Int;
};

like(
	$warnings[0],
	qr/^Possible missing comma after 'declare WholeNumber'/,
	'warning for missing comma',
);

done_testing;
