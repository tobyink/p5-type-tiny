=pod

=encoding utf-8

=head1 PURPOSE

Check type coercions can be unquoted L<Sub::Quote>.

=head1 DEPENDENCIES

Test is skipped if Sub::Quote is not available.

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
use Test::Requires "Sub::Quote";
use Test::TypeTiny;

use Sub::Quote;
use Type::Tiny;
use Types::Standard qw( ArrayRef Int );

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires "Sub::Quote";
use Test::Fatal;

use Sub::Quote;
use Type::Tiny;
use Types::Standard qw( Int Num ArrayRef );

my $type = Int->plus_coercions(
	Num,      q[ int($_) ],
	ArrayRef, q[ scalar(@$_) ],
);

my $coercion = $type->coercion;

my ($name, $code, $captures, $compiled_sub) = @{
	Sub::Quote::quoted_from_sub( \&$coercion );
};

ok(defined($code), 'Got back code from Sub::Quote');

my $coderef = eval "sub { $code }";

is(ref($coderef), 'CODE', '... which compiles OK');

is(
	$coderef->(42),
	42,
	"... which passes through values that don't need to be coerced",
);

ok(
	$coderef->(3.1)==3 && $coderef->([qw/foo bar/])==2,
	"... coerces values that can be coerced",
);

is_deeply(
	$coderef->({foo => 666}),
	{foo => 666},
	"... and passes through any values it can't handle",
);


done_testing;
