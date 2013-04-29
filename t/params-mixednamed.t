=pod

=encoding utf-8

=head1 PURPOSE

Test usage with mix of positional and named parameters.

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
use Types::Standard -types, "slurpy";

my $chk = compile(ClassName, slurpy Dict[
	foo => Int,
	bar => Str,
	baz => ArrayRef,
]);

is_deeply(
	[ $chk->("Type::Tiny", foo => 1, bar => "Hello", baz => []) ],
	[ "Type::Tiny", { foo => 1, bar => "Hello", baz => [] } ]
);

is_deeply(
	[ $chk->("Type::Tiny", bar => "Hello", baz => [], foo => 1) ],
	[ "Type::Tiny", { foo => 1, bar => "Hello", baz => [] } ]
);

like(
	exception { $chk->("Type::Tiny", foo => 1, bar => "Hello") },
	qr{does not meet type constraint .Dict},
);

done_testing;

