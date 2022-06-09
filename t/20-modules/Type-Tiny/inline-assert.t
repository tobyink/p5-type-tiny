=pod

=encoding utf-8

=head1 PURPOSE

Tests for Type::Tiny's C<inline_assert> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;
use Types::Standard qw( Int );

# Exceptions do seem to work on older Perls, but checking them with like()
# seems to break stuff, so just skip.
use constant SANE_PERL => ($] ge '5.008001');

my ($inline_assert, @VALUE, $r);
local $@;

note("INLINE ASSERTION, INLINABLE TYPE, NO TYPEVAR");
note($inline_assert = Int->inline_assert('$VALUE[0]'));

@VALUE = (12);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, 1234, 'successful check');

@VALUE = (1.2);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, undef, 'successful throw');
like($@, qr/Value "1.2" did not pass type constraint "Int"/, '... with correct exception') if SANE_PERL;

note("INLINE ASSERTION, INLINABLE TYPE, WITH TYPEVAR");
my $type = Int;
note($inline_assert = $type->inline_assert('$VALUE[0]', '$type'));

@VALUE = (12);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, 1234, 'successful check');

@VALUE = (1.2);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, undef, 'successful throw');
like($@, qr/Value "1.2" did not pass type constraint "Int"/, '... with correct exception') if SANE_PERL;

undef $type;
@VALUE = (1.2);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, undef, 'successful throw even when $type is undef');
like($@, qr/Value "1.2" did not pass type constraint "Int"/, '... with correct exception') if SANE_PERL;
is($@->type, undef, '... but the exception does not know which type it was thrown by') if SANE_PERL;

note("INLINE ASSERTION, NON-INLINABLE TYPE, NO TYPEVAR");
$type = Int->where(sub {1});  # cannot be inlined
undef $inline_assert;
my $e = exception {
	$inline_assert = $type->inline_assert('$VALUE[0]');
};
isnt($e, undef, 'cannot be done!');

note("INLINE ASSERTION, NON-INLINABLE TYPE, WITH TYPEVAR");
note($inline_assert = $type->inline_assert('$VALUE[0]', '$type'));

@VALUE = (12);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, 1234, 'successful check');

@VALUE = (1.2);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($r, undef, 'successful throw');
like($@, qr/Value "1.2" did not pass type constraint "Int"/, '... with correct exception') if SANE_PERL;

note("INLINE ASSERTION, NON-INLINABLE TYPE, WITH TYPEVAR AND EXTRAS");
note($inline_assert = $type->inline_assert('$VALUE[0]', '$type', foo => "bar"));
@VALUE = (1.2);
$@ = undef;
$r = eval "$inline_assert; 1234";
is($@->{foo}, 'bar', 'extras work') if SANE_PERL;

done_testing;

