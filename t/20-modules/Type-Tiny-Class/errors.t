=pod

=encoding utf-8

=head1 PURPOSE

Checks class type constraints throw sane error messages.

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
use Test::Fatal;

use Types::Standard qw(Int);
use Type::Tiny::Class;

like(
	exception { Type::Tiny::Class->new(parent => Int, class => 'Foo') },
	qr/^Class type constraints cannot have a parent/,
);

like(
	exception { Type::Tiny::Class->new(constraint => sub { 1 }, class => 'Foo') },
	qr/^Class type constraints cannot have a constraint coderef/,
);

like(
	exception { Type::Tiny::Class->new(inlined => sub { 1 }, class => 'Foo') },
	qr/^Class type constraints cannot have an inlining coderef/,
);

like(
	exception { Type::Tiny::Class->new() },
	qr/^Need to supply class name/,
);

{
	package Quux;
	our @ISA = qw();
	sub new { bless [], shift }
}

{
	package Quuux;
	our @ISA = qw();
}

{
	package Baz;
	our @ISA = qw(Quuux);
}

{
	package Bar;
	our @ISA = qw(Baz Quux);
}

my $e = exception {
	Type::Tiny::Class
		->new(name => "Elsa", class => "Foo")
		->assert_valid( Bar->new );
};

is_deeply(
	$e->explain,
	[
		'"Elsa" requires that the reference isa Foo',
		'The reference isa Bar, Baz, Quuux, and Quux',
	],
);

done_testing;
