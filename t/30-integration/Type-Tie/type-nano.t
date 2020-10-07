=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny works okay with Type::Nano.

=head1 DEPENDENCIES

Requires L<Type::Nano>; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Test::Requires 'Type::Nano';
use Types::Standard;
use Types::TypeTiny 'to_TypeTiny';
use Test::Fatal;
use Test::TypeTiny;

my $conv = to_TypeTiny( Type::Nano::ArrayRef );

should_pass(
	[ 1 .. 3 ],
	$conv,
);

should_fail(
	'Hello world',
	$conv,
);

like(
	exception { $conv->(undef) },
	qr/ArrayRef/,
	'get_message worked',
);

my $t1 = Types::Standard::ArrayRef->of( Type::Nano::Int );

should_pass(
	[ 1 .. 3 ],
	$t1,
);

should_fail(
	{},
	$t1,
);

should_fail(
	[ 1 .. 3, undef ],
	$t1,
);

done_testing;
