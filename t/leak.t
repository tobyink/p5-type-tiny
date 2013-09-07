=pod

=encoding utf-8

=head1 PURPOSE

Check for memory leaks.

=head1 DEPENDENCIES

L<Test::LeakTrace>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires 'Test::LeakTrace';
use Test::LeakTrace;

use Types::Standard 'Str';

eval { require Moo };

no_leaks_ok {
	my $x = Type::Tiny->new;
	undef($x);
} 'Type::Tiny->new';

no_leaks_ok {
	my $x = Type::Tiny->new->coercibles;
	undef($x);
} 'Type::Tiny->new->coercible';

done_testing;
