=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tie works with Clone::clone

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Requires 'Clone';
use Test::Fatal;

use Type::Tie;

use Types::Standard qw( Int );
use Clone qw(clone);

# Hashes

ttie my %hash, Int;

my $ref = \%hash;
my $hashDclone = clone(\%hash);

eval {
	$hashDclone->{a} = 1;
};
ok(! $@);

eval {
	$hashDclone->{a} = 'a';
};
ok($@);

# Arrays

ttie my @array, Int;

my $arrayDclone = clone(\@array);

eval {
	push @$arrayDclone, 1;
};
ok(! $@);

eval {
	push @$arrayDclone, 'a';
};
ok($@);

# Scalar

my $scalarContainer = [ '' ];

ttie $scalarContainer->[0], Int;

my $scalarContainerDclone = clone($scalarContainer);

eval {
	$scalarContainerDclone->[0] = 1;
};
ok(! $@);

eval {
	$scalarContainerDclone->[0] = 'a';
};
ok($@);

done_testing();
