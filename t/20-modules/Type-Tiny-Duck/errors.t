=pod

=encoding utf-8

=head1 PURPOSE

Checks duck type constraints throw sane error messages.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use Types::Standard qw(Int);
use Type::Tiny::Duck;

like(
	exception { Type::Tiny::Duck->new(parent => Int, methods => []) },
	qr/^Duck type constraints cannot have a parent/,
);

like(
	exception { Type::Tiny::Duck->new(constraint => sub { 1 }, methods => []) },
	qr/^Duck type constraints cannot have a constraint coderef/,
);

like(
	exception { Type::Tiny::Duck->new(inlined => sub { 1 }, methods => []) },
	qr/^Duck type constraints cannot have an inlining coderef/,
);

like(
	exception { Type::Tiny::Duck->new() },
	qr/^Need to supply list of methods/,
);

{
	package Bar;
	sub new { bless [], shift };
	sub shake { fail("aquiver") };
}

my $e = exception {
	Type::Tiny::Duck
		->new(name => "Elsa", methods => [qw/ shake rattle roll /])
		->assert_valid( Bar->new );
};

is_deeply(
	$e->explain,
	[
		'"Elsa" requires that the reference can "rattle", "roll", and "shake"',
		'The reference cannot "rattle"',
		'The reference cannot "roll"',
	],
);

done_testing;
