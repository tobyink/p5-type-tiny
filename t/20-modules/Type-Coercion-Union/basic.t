=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion::Union works.

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
use Test::Fatal;
use Test::TypeTiny;

use Types::Standard -types;
use Type::Utils;

my $RoundedInteger = declare RoundedInteger => as Int;
$RoundedInteger->coercion->add_type_coercions(Num, 'int($_)')->freeze;

should_pass("4", $RoundedInteger);
should_fail("1.1", $RoundedInteger);
should_fail("xyz", $RoundedInteger);

my $String3 = declare String3 => as StrMatch[qr/^.{3}$/];
$String3->coercion->add_type_coercions(Str, 'substr("$_   ", 0, 3)')->freeze;

should_pass("xyz", $String3);
should_fail("x", $String3);
should_fail("wxyz", $String3);

my $Union1 = union Union1 => [$RoundedInteger, $String3];

should_pass("3.4", $Union1);
should_pass("30", $Union1);
should_fail("3.12", $Union1);
should_fail("wxyz", $Union1);

is(
	$RoundedInteger->coerce("3.4"),
	"3",
	"RoundedInteger coerces from Num",
);

is(
	$RoundedInteger->coerce("xyz"),
	"xyz",
	"RoundedInteger does not coerce from Str",
);

is(
	$String3->coerce("30"),
	"30 ",
	"String3 coerces from Str",
);

my $arr = [];
is(
	$String3->coerce($arr),
	$arr,
	"String3 does not coerce from ArrayRef",
);

ok(
	$Union1->has_coercion,
	"unions automatically have a coercion if their child constraints do",
);

note $Union1->coercion->inline_coercion('$X');

ok(
	union([Str, ArrayRef]),
	"unions do not automatically have a coercion if their child constraints do not",
);

is(
	$Union1->coerce("4"),
	"4",
	"Union1 does not need to coerce an Int",
);

is(
	$Union1->coerce("xyz"),
	"xyz",
	"Union1 does not need to coerce a String3",
);

is(
	$Union1->coerce("3.1"),
	"3.1",
	"Union1 does not need to coerce a String3, even if it looks like a Num",
);

is(
	$Union1->coerce("abcde"),
	"abc",
	"Union1 coerces Str -> String3",
);

is(
	$Union1->coerce("3.123"),
	"3",
	"given the choice of two valid coercions, Union1 prefers RoundedInteger because it occurs sooner",
);

is(
	$Union1->coerce($arr),
	$arr,
	"Union1 cannot coerce an arrayref",
);

like(
	exception { $Union1->coercion->add_type_coercions(ArrayRef, q[ scalar(@$_) ]) },
	qr/^Adding coercions to Type::Coercion::Union not currently supported/,
	"Cannot add to Type::Tiny::Union's coercion",
);

done_testing;
