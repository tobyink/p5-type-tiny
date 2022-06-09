=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny refcount stuff.

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
use Test::Requires 'Devel::Refcount';
use Devel::Refcount 'refcount';
use Test::TypeTiny;
use Type::Tiny;
use Type::Registry;

my $ref = [];
my $orig_count = refcount( $ref );
note "COUNT: $orig_count";

{
	my $type = 'Type::Tiny'->new(
		name       => 'AnswerToLifeTheUniverseAndEverything',
		constraint => sub { $_ eq 42 },
		inlined    => sub { my $var = pop; "$var eq 42" },
		dummy_attr => $ref,
	);
	
	is refcount( $ref ), 1 + $orig_count;
	
	should_fail( 41, $type );
	should_pass( 42, $type );
	
	is refcount( $ref ), 1 + $orig_count;
}

is refcount( $ref ), $orig_count;

done_testing;
