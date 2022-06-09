=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints can be unquoted L<Sub::Quote>.

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
use Test::Fatal;

use Sub::Quote;
use Type::Tiny;
use Types::Standard qw( Int );

my $type = Int;

my ($name, $code, $captures, $compiled_sub) = @{
	Sub::Quote::quoted_from_sub( \&$type );
};

ok(defined($code), 'Got back code from Sub::Quote');

my $coderef = eval "sub { $code }";

is(ref($coderef), 'CODE', '... which compiles OK');

ok($coderef->(42), '... and seems to work');

like(
	exception { $coderef->([]) },
	qr/\AReference \[\] did not pass type constraint "Int"/,
	'... and throws exceptions properly',
);

done_testing;
