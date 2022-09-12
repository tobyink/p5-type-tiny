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
	positional => [
		Str,
		Str,
		Any, { slurpy => 1 },
	],
);

my ( $in, $out, $slurpy ) = $sig->( qw/ IN OUT FOO BAR / );

is( $in,  'IN'  );
is( $out, 'OUT' );
is_deeply( $slurpy, [ 'FOO', 'BAR' ] );

done_testing;
