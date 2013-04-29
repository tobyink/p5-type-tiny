=pod

=encoding utf-8

=head1 PURPOSE

Test usage with optional parameters.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

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
	qr{^Value "HASH\(\w+\)" in \$_\[2\] does not meet type constraint "Optional\[ArrayRef\]"},
);

like(
	exception { $chk->() },
	qr{^Value "" in \$_\[0\] does not meet type constraint "Num"},
);

done_testing;

