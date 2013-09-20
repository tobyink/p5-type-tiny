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

BEGIN { plan skip_all => 'Perl 5.10.0' if $] == 5.010 };

use Test::Requires 'Test::LeakTrace';
use Test::LeakTrace;

use Types::Standard qw( ArrayRef HashRef );

eval { require Moo };

no_leaks_ok {
	my $x = Type::Tiny->new;
	undef($x);
} 'Type::Tiny->new';

no_leaks_ok {
	my $x = Type::Tiny->new->coercibles;
	undef($x);
} 'Type::Tiny->new->coercible';

no_leaks_ok {
	my $x = ArrayRef | HashRef;
	my $y = HashRef | ArrayRef;
	undef($_) for $x, $y;
} 'ArrayRef | HashRef';

no_leaks_ok {
	my $x = ArrayRef[HashRef];
	my $y = HashRef[ArrayRef];
	undef($_) for $x, $y;
} 'ArrayRef[HashRef]';

no_leaks_ok {
	my $x = Type::Tiny->new;
	$x->check(1);
	undef($x);
} 'Type::Tiny->new->check';

no_leaks_ok {
	my $x = ArrayRef->plus_coercions(HashRef, sub { [sort keys %$_] });
	my $a = $x->coerce({bar => 1, baz => 2});
	undef($_) for $x, $a;
} 'ArrayRef->plus_coercions->coerce';

done_testing;
