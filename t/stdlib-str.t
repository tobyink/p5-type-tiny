=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<Bytes> and C<Chars> from Types::Standard.

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

use Test::More;
use Test::TypeTiny;

use Encode;
use Types::Standard qw( Str Bytes Chars );
use Type::Utils;

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

done_testing;
