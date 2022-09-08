=pod

=encoding utf-8

=head1 PURPOSE

Checks enum type constraints work.

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
use Test::TypeTiny;
use Type::Utils qw< enum >;

use constant FBB => enum(FBB => [qw/foo bar baz/]);

isa_ok(FBB, "Type::Tiny", "FBB");
isa_ok(FBB, "Type::Tiny::Enum", "FBB");

should_pass("foo", FBB);
should_pass("bar", FBB);
should_pass("baz", FBB);

should_fail("quux", FBB);
should_fail(" foo", FBB);
should_fail("foo\n", FBB);
should_fail("\nfoo", FBB);
should_fail("\nfoo\n", FBB);
should_fail("foo|", FBB);
should_fail("|foo", FBB);
should_fail(undef, FBB);
should_fail({}, FBB);
should_fail(\$_, FBB) for "foo", "bar", "baz";

is_deeply(
	[sort @{FBB->values}],
	[sort qw/foo bar baz/],
	'FBB->values works',
);

is_deeply(
	FBB->values,
	[qw/foo bar baz/],
	'FBB->values retains order',
);

use Scalar::Util qw(refaddr);

is(
	refaddr(FBB->compiled_check),
	refaddr(enum(FBB2 => [qw/foo foo foo bar baz/])->compiled_check),
	"don't create duplicate coderefs",
);

{
	my $exportables = FBB->exportables;
	my %exportables = map {; $_->{name} => $_->{code} } @$exportables;
	is_deeply(
		[ sort keys %exportables ],
		[ sort qw( FBB is_FBB assert_FBB to_FBB FBB_FOO FBB_BAR FBB_BAZ ) ],
		'correct exportables',
	) or diag explain( \%exportables );

	is(
		$exportables{FBB_BAZ}->(),
		'baz',
		'exported constant actually works',
	);
}

{
	my $type = enum( FBB2 => [qw/ foo bar baz ... /] );
	my $exportables = $type->exportables;
	my %exportables = map {; $_->{name} => $_->{code} } @$exportables;
	is_deeply(
		[ sort keys %exportables ],
		[ sort qw( FBB2 is_FBB2 assert_FBB2 to_FBB2 ) ],
		'correct exportables for non-word-safe enum',
	) or diag explain( \%exportables );
}

done_testing;
