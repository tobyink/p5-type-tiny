=pod

=encoding utf-8

=head1 PURPOSE

Tests integration with L<Data::Constraint>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;
use Test::Fatal;

use Test::Requires 'Data::Constraint';
use Types::TypeTiny qw( to_TypeTiny );

'Data::Constraint'->add_constraint(
	'FortyTwo',
	'run'         => sub { defined $_[1] and not ref $_[1] and $_[1] eq 42 },
	'description' => 'True if the value reveals the answer to life, the universe, and everything',
);

my $type = to_TypeTiny( 'Data::Constraint'->get_by_name( 'FortyTwo' ) );

should_pass( 42, $type );
should_fail( "42.0", $type );
should_fail( [ 42 ], $type );
should_fail( undef, $type );

my $e = exception { $type->(43) };

like $e, qr/Value "43" did not pass type constraint "FortyTwo"/, 'error message';

done_testing;
