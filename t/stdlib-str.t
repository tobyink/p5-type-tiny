=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<Bytes> and C<Chars> from Types::Standard;
and checks the C<Decode> and C<Encode> parameterized coercions.

Checks the C<Split> and C<Join> coercions in L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );
use utf8;

use Test::More tests => 2;
use Test::TypeTiny;

use Encode;
use Types::Standard qw( Str Bytes Chars Encode Decode ArrayRef Join Split );
use Type::Utils;

subtest "Check Str, Bytes and Chars; Encode and Decode" => sub
{
	plan tests => 19;
	
	my $chars          = "café";
	my $bytes_utf8     = Encode::encode("utf-8",      $chars);
	my $bytes_western  = Encode::encode("iso-8859-1", $chars);

	is(length($chars),         4, 'length $chars == 4');
	is(length($bytes_utf8),    5, 'length $bytes_utf8 == 5');
	is(length($bytes_western), 4, 'length $bytes_western == 4');

	ok( utf8::is_utf8($chars),         'utf8::is_utf8 $chars');
	ok(!utf8::is_utf8($bytes_utf8),    'not utf8::is_utf8 $bytes_utf8');
	ok(!utf8::is_utf8($bytes_western), 'not utf8::is_utf8 $bytes_western');

	should_pass($chars, Str);
	should_pass($chars, Chars);
	should_fail($chars, Bytes);

	should_pass($bytes_utf8, Str);
	should_fail($bytes_utf8, Chars);
	should_pass($bytes_utf8, Bytes);

	should_pass($bytes_western, Str);
	should_fail($bytes_western, Chars);
	should_pass($bytes_western, Bytes);

	my $BytesUTF8 = Bytes + Encode["utf-8"];

	is(
		$BytesUTF8->coerce($chars),
		$bytes_utf8,
		'coerce using Bytes + Encode["utf-8"]',
	);

	my $BytesWestern = Bytes + Encode["iso-8859-1"];

	is(
		$BytesWestern->coerce($chars),
		$bytes_western,
		'coerce using Bytes + Encode["iso-8859-1"]',
	);

	my $CharsFromUTF8 = Chars + Decode["utf-8"];

	is(
		$CharsFromUTF8->coerce($bytes_utf8),
		$chars,
		'coerce using Chars + Decode["utf-8"]',
	);

	my $CharsFromWestern = Chars + Decode["iso-8859-1"];

	is(
		$CharsFromWestern->coerce($bytes_western),
		$chars,
		'coerce using Chars + Decode["iso-8859-1"]',
	);
};

subtest "Check ArrayRef[Str], ArrayRef[Bytes] and ArrayRef[Chars]; Join and Split" => sub
{
	plan tests => 26;
	
	my $chars          = "Café Paris|Garçon";
	my $bytes_utf8     = Encode::encode("utf-8",      $chars);
	my $bytes_western  = Encode::encode("iso-8859-1", $chars);

	is(length($chars),         17, 'length $chars == 17');
	is(length($bytes_utf8),    19, 'length $bytes_utf8 == 19');
	is(length($bytes_western), 17, 'length $bytes_western == 17');

	my $SplitSpace = (ArrayRef[Str]) + (Split[qr/\s/]);
	my $SplitPipe  = (ArrayRef[Str]) + (Split[qr/\|/]);
	my $ArrChars   = ArrayRef[Chars];
	my $ArrBytes   = ArrayRef[Bytes];

	ok($SplitSpace->can_be_inlined, '$SplitSpace can be inlined');
	ok($SplitPipe->can_be_inlined, '$SplitPipe can be inlined');

	is_deeply(
		$SplitSpace->coerce($chars),
		[ "Café", "Paris|Garçon" ],
		'$SplitSpace->coerce($chars)',
	);

	is_deeply(
		$SplitSpace->coerce($bytes_utf8),
		[ map Encode::encode("utf-8", $_), "Café", "Paris|Garçon" ],
		'$SplitSpace->coerce($bytes_utf8)',
	);

	is_deeply(
		$SplitSpace->coerce($bytes_western),
		[ map Encode::encode("iso-8859-1", $_), "Café", "Paris|Garçon" ],
		'$SplitSpace->coerce($bytes_western)',
	);

	should_pass($SplitSpace->coerce($chars), ArrayRef[Str]);
	should_pass($SplitSpace->coerce($chars), ArrayRef[Chars]);
	should_fail($SplitSpace->coerce($chars), ArrayRef[Bytes]);

	should_pass($SplitSpace->coerce($bytes_utf8), ArrayRef[Str]);
	should_fail($SplitSpace->coerce($bytes_utf8), ArrayRef[Chars]);
	should_pass($SplitSpace->coerce($bytes_utf8), ArrayRef[Bytes]);

	should_pass($SplitSpace->coerce($bytes_western), ArrayRef[Str]);
	should_fail($SplitSpace->coerce($bytes_western), ArrayRef[Chars]);
	should_pass($SplitSpace->coerce($bytes_western), ArrayRef[Bytes]);

	is_deeply(
		my $arr_chars = $SplitPipe->coerce($chars),
		[ "Café Paris", "Garçon" ],
		'$SplitPipe->coerce($chars)',
	);

	is_deeply(
		my $arr_bytes_utf8 = $SplitPipe->coerce($bytes_utf8),
		[ map Encode::encode("utf-8", $_), "Café Paris", "Garçon" ],
		'$SplitPipe->coerce($bytes_utf8)',
	);

	is_deeply(
		my $arr_bytes_western = $SplitPipe->coerce($bytes_western),
		[ map Encode::encode("iso-8859-1", $_), "Café Paris", "Garçon" ],
		'$SplitPipe->coerce($bytes_western)',
	);

	my $JoinPipe = Str + Join["|"];

	is(
		$_ = $JoinPipe->coerce($arr_chars),
		$chars,
		'$JoinPipe->coerce($arr_chars)',
	);
	should_pass($_, Chars);

	is(
		$_ = $JoinPipe->coerce($arr_bytes_utf8),
		$bytes_utf8,
		'$JoinPipe->coerce($arr_bytes_utf8)',
	);
	should_pass($_, Bytes);

	is(
		$_ = $JoinPipe->coerce($arr_bytes_western),
		$bytes_western,
		'$JoinPipe->coerce($arr_bytes_western)',
	);
	should_pass($_, Bytes);
};

