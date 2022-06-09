=pod

=encoding utf-8

=head1 PURPOSE

Tests exporting to two roles; tries to avoid reporting conflicts.

=head1 DEPENDENCIES

Requires L<Exporter> 5.59 and L<Role::Tiny> 1.000000;
test skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

This test case is based on a script provided by Kevin Dawson.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::Requires { "Exporter"   => 5.59 };
use Test::Requires { "Role::Tiny" => 1.000000 };
use Test::More;
use Test::Fatal;

{
	package Local::Role1;
	use Role::Tiny;
	use Types::Standard "Str";
}

{
	package Local::Role2;
	use Role::Tiny;
	use Types::Standard "Str";
}

my $e = exception {
	package Local::Class1;
	use Role::Tiny::With;
	with qw( Local::Role1 Local::Role2 );
};

is($e, undef, 'no exception when trying to compose two roles that use type constraints');

use Scalar::Util "refaddr";
note refaddr(\&Local::Role1::Str);
note refaddr(\&Local::Role2::Str);

done_testing;
