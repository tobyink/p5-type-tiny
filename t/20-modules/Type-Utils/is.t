=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Utils> C<is> function.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings ':all';
use Test::Fatal;

use Type::Utils "is" => { -as => "isntnt" }, "assert";
use Types::Standard "Str";

ok ! isntnt(Str, undef);
ok isntnt(Str, '');
ok ! isntnt('Str', undef);
ok isntnt('Str', '');

my @warnings = warnings {
	ok ! isntnt( undef, undef );
};

like(
	$warnings[0],
	qr/Expected type, but got undef/,
	'warning from is(undef, $value)'
);

@warnings = warnings {
	ok ! isntnt( [], undef );
};

like(
	$warnings[0],
	qr/Expected type, but got reference \[/,
	'warning from is([], $value)'
);

is assert(Str, 'foo'), 'foo';
like exception { assert(Str, []) }, qr/did not pass type constraint/;
like exception { assert('*', []) }, qr/Expected type, but got value/;

done_testing;
