=pod

=encoding utf-8

=head1 PURPOSE

Checks enum type constraints throw sane error messages.

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
use Type::Tiny::Enum;

like(
	exception { Type::Tiny::Enum->new(parent => Int) },
	qr/^Enum type constraints cannot have a parent constraint/,
);

like(
	exception { Type::Tiny::Enum->new(constraint => sub { 1 }) },
	qr/^Enum type constraints cannot have a constraint coderef/,
);

like(
	exception { Type::Tiny::Enum->new(inlined => sub { 1 }) },
	qr/^Enum type constraints cannot have a inlining coderef/,
);

like(
	exception { Type::Tiny::Enum->new() },
	qr/^Need to supply list of values/,
);

ok(
	!exception { Type::Tiny::Enum->new(values => [qw/foo bar/]) },
);

done_testing;
