=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> C<compile_named_oo> function.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Type::Params qw( compile_named_oo );
use Types::Standard qw( -types );


my $coderef = compile_named_oo(
	foo    => Int,
	bar    => Optional[Int],
	baz    => Optional[HashRef], { getter => 'bazz', predicate => 'haz' },
);

ok(CodeRef->check($coderef), 'compile_named_oo returns a coderef');

my @object;
$object[0] = $coderef->(  foo => 42, bar => 69, baz => { quux => 666 }  );
$object[1] = $coderef->({ foo => 42, bar => 69, baz => { quux => 666 } });
$object[2] = $coderef->(  foo => 42  );
$object[3] = $coderef->({ foo => 42 });

for my $i (0 .. 1) {
	ok(Object->check($object[$i]), "\$object[$i] is an object");
	can_ok($object[$i], qw( foo bar has_bar bazz haz ));
	is($object[$i]->foo, 42, "\$object[$i]->foo == 42");
	is($object[$i]->bar, 69, "\$object[$i]->bar == 69");
	is($object[$i]->bazz->{quux}, 666, "\$object[$i]->bazz->{quux} == 666");
	ok($object[$i]->has_bar, "\$object[$i]->has_bar");
	ok($object[$i]->haz, "\$object[$i]->haz");
	ok(! $object[$i]->can("has_foo"), 'no has_foo method');
	ok(! $object[$i]->can("has_baz"), 'no has_baz method');
}

for my $i (2 .. 3) {
	ok(Object->check($object[$i]), "\$object[$i] is an object");
	can_ok($object[$i], qw( foo bar has_bar bazz haz ));
	is($object[$i]->foo, 42, "\$object[$i]->foo == 42");
	is($object[$i]->bar, undef, "not defined \$object[$i]->bar");
	is($object[$i]->bazz, undef, "not defined \$object[$i]->bazz");
	ok(! $object[$i]->has_bar, "!\$object[$i]->has_bar");
	ok(! $object[$i]->haz, "!\$object[$i]->haz");
	ok(! $object[$i]->can("has_foo"), 'no has_foo method');
	ok(! $object[$i]->can("has_baz"), 'no has_baz method');
}


my $e = exception {
	compile_named_oo( 999 => Int );
};
ok(defined $e, 'exception thrown for bad accessor name');
like("$e", qr/bad accessor name/i, 'correct message');


my $coderef2 = compile_named_oo(
	bar    => Optional[ArrayRef],
	baz    => Optional[CodeRef], { getter => 'bazz', predicate => 'haz' },
	foo    => Num,
);
my $coderef2obj = $coderef2->(foo => 1.1, bar => []);
is(ref($object[0]), ref($coderef2obj), 'packages reused when possible');

my $details = compile_named_oo( { want_details => 1 }, fooble => Int );
like($details->{source}, qr/fooble/, 'want_details');

{
	my $coderef3 = compile_named_oo(
		{
			head         => [ Int->plus_coercions( Num, sub {int $_} ) ],
			tail         => [ ArrayRef, ArrayRef ],
			want_details => 1,
		},
		bar    => Optional[ArrayRef],
		baz    => Optional[CodeRef], { getter => 'bazz', predicate => 'haz' },
		foo    => Num,
	);

	note($coderef3->{source});

	is($coderef3->{max_args}, 9);
	ok($coderef3->{min_args} >= 3);

	my @r = $coderef3->{closure}->(1.1, foo => 1.2, bar => [], [1,2,3], ["foo"]);

	is($r[0], 1);
	is($r[1]->foo, 1.2);
	is_deeply($r[1]->bar, []);
	is($r[1]->bazz, undef);
	ok(!$r[1]->haz);
	is_deeply($r[2], [1,2,3]);
	is_deeply($r[3], ["foo"]);
}

{
	my $coderef3 = compile_named_oo(
		{
			head         => [ Int->where('1')->plus_coercions( Num->where('1'), q{int $_} ) ],
			tail         => [ ArrayRef->where('1'), ArrayRef ],
			want_details => 1,
		},
		bar    => Optional[ArrayRef],
		baz    => Optional[CodeRef], { getter => 'bazz', predicate => 'haz' },
		foo    => Num,
	);

	note($coderef3->{source});

	is($coderef3->{max_args}, 9);
	ok($coderef3->{min_args} >= 3);

	my @r = $coderef3->{closure}->(1.1, foo => 1.2, bar => [], [1,2,3], ["foo"]);

	is($r[0], 1);
	is($r[1]->foo, 1.2);
	is_deeply($r[1]->bar, []);
	is($r[1]->bazz, undef);
	ok(!$r[1]->haz);
	is_deeply($r[2], [1,2,3]);
	is_deeply($r[3], ["foo"]);
}

{
	my $coderef3 = compile_named_oo(
		{
			head         => [ Int->where(sub{1})->plus_coercions( Num->where(sub{1}), sub {int $_} ) ],
			tail         => [ ArrayRef->where(sub{1}), ArrayRef ],
			want_details => 1,
		},
		bar    => Optional[ArrayRef],
		baz    => Optional[CodeRef], { getter => 'bazz', predicate => 'haz' },
		foo    => Num,
	);

	note($coderef3->{source});

	is($coderef3->{max_args}, 9);
	ok($coderef3->{min_args} >= 3);

	my @r = $coderef3->{closure}->(1.1, foo => 1.2, bar => [], [1,2,3], ["foo"]);

	is($r[0], 1);
	is($r[1]->foo, 1.2);
	is_deeply($r[1]->bar, []);
	is($r[1]->bazz, undef);
	ok(!$r[1]->haz);
	is_deeply($r[2], [1,2,3]);
	is_deeply($r[3], ["foo"]);
}

{
	package Local::Foo;
	my $c;
	sub bar {
		$c ||= ::compile_named_oo( foo => ::Int );
		return $c->(@_);
	}
}

my $args = Local::Foo::bar( foo => 42 );
ok Type::Params::ArgsObject->check($args), 'ArgsObject';
ok Type::Params::ArgsObject->of('Local::Foo::bar')->check($args), 'ArgsObject["Local::Foo::bar"]';
ok !Type::Params::ArgsObject->of('Local::Foo::baz')->check($args), '!ArgsObject["Local::Foo::barz"]';
note explain($args);

done_testing;
