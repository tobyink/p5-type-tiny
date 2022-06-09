=pod

=encoding utf-8

=head1 PURPOSE

A test for type constraint inflation from L<Moo> to L<Moose>.

=head1 DEPENDENCIES

Requires Moo 1.003000 and Moose 2.0800; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires { 'Moo' => '1.003000' };
use Test::Requires { 'Moose' => '2.0800' };

use Types::Standard qw/Str HashRef/;
my $type = HashRef[Str];

{
	package AAA;
	BEGIN { $INC{'AAA.pm'} = __FILE__ };
	use Moo::Role;
	has foo => (
		is     => 'ro',
		isa    => $type,
		traits => ['Hash'],
	);
}

{
	package BBB;
	use Moose;
	with 'AAA';
}

ok not exception {
	'BBB'->new(
		foo => {
			a => 'b'
		}
	);
};

done_testing;
