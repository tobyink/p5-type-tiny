=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> usage with optional parameters.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw(compile);
use Types::Standard -types;

my $chk = compile(Num, Optional[Int], Optional[ArrayRef], Optional[HashRef]);

is_deeply(
	[ $chk->(1.1, 2, [], {}) ],
	[ 1.1, 2, [], {} ]
);

is_deeply(
	[ $chk->(1.1, 2, []) ],
	[ 1.1, 2, [] ]
);

is_deeply(
	[ $chk->(1.1, 2) ],
	[ 1.1, 2 ]
);

is_deeply(
	[ $chk->(1.1) ],
	[ 1.1 ]
);

like(
	exception { $chk->(1.1, 2, {}) },
	qr{^Reference \{\} did not pass type constraint "Optional\[ArrayRef\]" \(in \$_\[2\]\)},
);

like(
	exception { $chk->() },
	qr{^Wrong number of parameters; got 0; expected 1 to 4},
);

like(
	exception { $chk->(1 .. 5) },
	qr{^Wrong number of parameters; got 5; expected 1 to 4},
);

my $chk2 = compile(1, 0, 0);
like(
	exception { $chk2->() },
	qr{^Wrong number of parameters; got 0; expected 1 to 3},
);

like(
	exception { $chk->(1, 2, undef) },
	qr{^Undef did not pass type constraint},
);

done_testing;

