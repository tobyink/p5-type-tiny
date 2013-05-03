=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> with type constraints that cannot be inlined.

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
use Types::Standard qw(Num);
use Type::Utils;

my $NumX = declare NumX => as Num, where { $_ != 42 };

my $check;
sub nth_root
{
	$check ||= compile( $NumX, $NumX );
	[ $check->(@_) ];
}

is_deeply(
	nth_root(1, 2),
	[ 1, 2 ],
	'(1, 2)',
);

is_deeply(
	nth_root("1.1", 2),
	[ "1.1", 2 ],
	'(1.1, 2)',
);

{
	my $e = exception { nth_root() };
	like($e, qr{^Wrong number of parameters \(0\); expected 2}, '()');
}

{
	my $e = exception { nth_root(1) };
	like($e, qr{^Wrong number of parameters \(1\); expected 2}, '(1)');
}

{
	my $e = exception { nth_root(undef, 1) };
	like($e, qr{^Undef in \$_\[0\] does not meet type constraint "NumX"}, '(undef, 1)');
}

{
	my $e = exception { nth_root(41, 42) };
	like($e, qr{^Value "42" in \$_\[1\] does not meet type constraint "NumX"}, '(42)');
}

done_testing;

