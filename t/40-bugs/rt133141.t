=pod

=encoding utf-8

=head1 PURPOSE

Make sure that L<Tuple[Enum["test string"]]> can initialize in XS

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=133141>.

=head1 AUTHOR

Andrew Ruder E<lt>andy@aeruder.net<gt>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Andrew Ruder

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';
use Test::More;
use Type::Tiny;
use Types::Standard qw[ Tuple Enum ];
use Type::Parser qw( eval_type );
use Type::Registry;

plan tests => 10;

my $type1 = Tuple[Enum[qw(a b)]];
ok $type1->check(["a"]), '"a" matches Enum[qw(a b)]';
ok !$type1->check(["c"]), '"c" does not match Enum[qw(a b)]';

my $type2 = Tuple[Enum["foo bar"]];
ok $type2->check(["foo bar"]), '"foo bar" matches Enum["foo bar"]';
ok !$type2->check(["baz"]), '"baz" does not match Enum["foo bar"]';

my $type3 = Tuple[Enum["test\""]];
ok $type3->check(["test\""]), '"test\"" matches Enum["test\""]';
ok !$type3->check(["baz"]), '"baz" does not match Enum["test\""]';

my $type4 = Tuple[Enum["hello, world"]];
ok $type4->check(["hello, world"]), '"hello, world" matches Enum["hello, world"]';
ok !$type4->check(["baz"]), '"baz" does not match Enum["hello, world"]';

my $reg = Type::Registry->for_me;
$reg->add_types("Types::Standard");
my $type5 = eval_type("Tuple[Enum[\"hello, world\"]]", $reg);
ok $type5->check(["hello, world"]), "eval_type() evaluates quoted strings";
ok !$type5->check(["baz"]), "eval_type() evaluates quoted strings and doesn't pass 'baz'";
