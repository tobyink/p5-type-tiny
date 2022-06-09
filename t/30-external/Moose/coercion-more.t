=pod

=encoding utf-8

=head1 PURPOSE

Test for the good old "You cannot coerce an attribute unless its
type has a coercion" error.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moose 2.1200 is not available.

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
use Test::Requires { Moose => '2.1200' };
use Test::Fatal;
use Test::TypeTiny qw( matchfor );

my $e;

{
	package Local::Class;
	
	use Moose;
	use BiggerLib -all;
	
	::isa_ok(BigInteger, "Moose::Meta::TypeConstraint");
	
	has small  => (is => "rw", isa => SmallInteger, coerce => 1);
	has big    => (is => "rw", isa => BigInteger, coerce => 1);
	
	$e = ::exception {
		has big_nc => (is => "rw", isa => BigInteger->no_coercions, coerce => 1);
	};
}

like(
	$e,
	qr{^You cannot coerce an attribute .?big_nc.? unless its type .?\w+.? has a coercion},
	"no_coercions and friends available on Moose type constraint objects",
);

done_testing;
