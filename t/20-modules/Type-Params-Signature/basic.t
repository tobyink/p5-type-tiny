=pod

=encoding utf-8

=head1 PURPOSE

Basic tests that C<< Type::Params::Signature->new_from_compile >> works.

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

use Types::Standard -types;
use Type::Params::Signature;

my $sig = 'Type::Params::Signature'->new_from_compile(
	named => (
		{ head => [ Any ], quux => 123 },
		{ quux => 'xyzzy' },
		foo => Int, { quux => 123 },
		bar => Str,
	),
);

is( $sig->{quux}, 'xyzzy' );

ok( not $sig->head->[0]->has_name );
ok( $sig->head->[0]->has_type );
is( $sig->head->[0]->name, undef );
is( $sig->head->[0]->type, Any );

ok( $sig->has_parameters );
is( scalar( @{ $sig->parameters } ), 2 );

ok( $sig->parameters->[0]->has_name );
ok( $sig->parameters->[0]->has_type );
is( $sig->parameters->[0]->name, 'foo' );
is( $sig->parameters->[0]->type, Int );
is( $sig->parameters->[0]->{quux}, 123 );

ok( $sig->parameters->[1]->has_name );
ok( $sig->parameters->[1]->has_type );
is( $sig->parameters->[1]->name, 'bar' );
is( $sig->parameters->[1]->type, Str );

done_testing;
