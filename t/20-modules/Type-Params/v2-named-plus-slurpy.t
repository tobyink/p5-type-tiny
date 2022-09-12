=pod

=encoding utf-8

=head1 PURPOSE

Named slurpy parameter tests for modern Type::Params v2 API.

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

use Types::Common -sigs, -types;

my $sig = signature(
	named => [
		in      => Str,
		out     => Str,
		options => Any, { slurpy => 1 },
	],
);

my ( $arg ) = $sig->(
	in  => 'IN',
	out => 'OUT',
	foo => 'FOO',
	bar => 'BAR',
);

is( $arg->in,  'IN'  );
is( $arg->out, 'OUT' );
is_deeply(
	$arg->options,
	{ foo => 'FOO', bar => 'BAR' },
);

done_testing;
