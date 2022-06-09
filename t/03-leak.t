=pod

=encoding utf-8

=head1 PURPOSE

Check for memory leaks.

These tests are not comprehensive; chances are that there are still
memory leaks lurking somewhere in Type::Tiny. If you have any concrete
suggestions for things to test, or fixes for identified memory leaks,
please file a bug report.

L<https://rt.cpan.org/Ticket/Create.html?Queue=Type-Tiny>.

=head1 DEPENDENCIES

L<Test::LeakTrace>.

This test is skipped on Perl < 5.10.1 because I'm not interested in
jumping through hoops for ancient versions of Perl.

=head1 MISC ATTRIBUTE DECORATION

If Perl has been compiled with Misc Attribute Decoration (MAD) enabled,
then this test may fail. If you don't know what MAD is, then don't
worry: you probably don't have it enabled.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Config;

BEGIN { plan skip_all => 'Devel::Cover'  if $INC{'Devel/Cover.pm'} };
BEGIN { plan skip_all => 'Perl < 5.10.1' if $] < 5.010001 };
BEGIN { plan skip_all => 'useithreads'   if $Config{'useithreads'} };

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
