=pod

=encoding utf-8

=head1 PURPOSE

Tests that Type::Params supports C<default_on_undef>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Types::Common -types;
use Type::Params -sigs;

signature_for foo1 => ( pos => [ Optional, { default => 42                          } ], next => sub { shift } );
signature_for foo2 => ( pos => [ Optional, { default => 42, default_on_undef => !!1 } ], next => sub { shift } );

is foo1(60), 60;
is foo1(42), 42;
is foo1(), 42;
is foo1(undef), undef;
is foo1(''), '';

is foo2(60), 60;
is foo2(42), 42;
is foo2(), 42;
is foo2(undef), 42;
is foo2(''), '';

signature_for foo3 => ( named => [ foo => Optional, { default => 42                          } ], next => sub { shift->foo } );
signature_for foo4 => ( named => [ foo => Optional, { default => 42, default_on_undef => !!1 } ], next => sub { shift->foo } );

is foo3(foo=>60), 60;
is foo3(foo=>42), 42;
is foo3(), 42;
is foo3(foo=>undef), undef;
is foo3(foo=>''), '';

is foo4(foo=>60), 60;
is foo4(foo=>42), 42;
is foo4(), 42;
is foo4(foo=>undef), 42;
is foo4(foo=>''), '';

done_testing;
