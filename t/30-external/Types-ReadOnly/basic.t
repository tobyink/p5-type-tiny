=pod

=encoding utf-8

=head1 PURPOSE

L<Types::ReadOnly> does some frickin weird stuff with parameterization.
Check it all works!

=head1 DEPENDENCIES

Test is skipped if Types::ReadOnly 0.003 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );
use Test::More;
use Test::Requires { "Types::ReadOnly" => '0.003' };
use Test::Fatal;

use Types::Standard -types;
use Types::ReadOnly -types;

my $UnitHash = Dict->of(
	magnitude => Num,
	unit      => Optional[Str],
)->plus_coercions(
	Str ,=> q{ do { my($m,$u) = split / /; { magnitude => $m, unit => $u } } },
);

my $LockedUnitHash = Locked[$UnitHash];

my $thirtymetres = $LockedUnitHash->coerce('30 m');
is($thirtymetres->{magnitude}, 30);
is($thirtymetres->{unit}, 'm');

my $e = exception { $thirtymetres->{shizzle}++ };
like($e, qr/disallowed key/);

done_testing;
