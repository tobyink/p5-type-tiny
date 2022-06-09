=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with named parameters.

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

use Type::Params qw(compile);
use Types::Standard -types, "slurpy";

my $chk = compile slurpy Dict[
	foo => Int,
	bar => Str,
	baz => ArrayRef,
];

is_deeply(
	[ $chk->(foo => 1, bar => "Hello", baz => []) ],
	[ { foo => 1, bar => "Hello", baz => [] } ]
);

is_deeply(
	[ $chk->(bar => "Hello", baz => [], foo => 1) ],
	[ { foo => 1, bar => "Hello", baz => [] } ]
);

like(
	exception { $chk->(foo => 1, bar => "Hello") },
	qr{did not pass type constraint "Dict},
);

my $chk2 = compile slurpy Dict[
	foo => Int,
	bar => Str,
	baz => Optional[ArrayRef],
];

is_deeply(
	[ $chk2->(foo => 1, bar => "Hello") ],
	[ { foo => 1, bar => "Hello" } ]
);

like(
	exception { $chk2->(foo => 1, bar => "Hello", zab => []) },
	qr{did not pass type constraint "Dict},
);

done_testing;

