=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works.

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

use Type::Tiny;

ok("Type::Tiny"->can('new'), 'Type::Tiny can works for valid methods');
ok(
	!"Type::Tiny"->can('will_never_be_a_method'),
	'Type::Tiny can works for invalid methods'
);

my $Any = "Type::Tiny"->new(name => "Any");
ok(!$Any->is_anon, "Any is not anon");
is($Any->name, "Any", "Any is called Any");

ok($Any->can_be_inlined, 'Any can be inlined');

should_pass($_, $Any)
	for 1, 1.2, "Hello World", [], {}, undef, \*STDOUT;

like(
	exception { $Any->create_child_type(name => "1") },
	qr{^"1" is not a valid type name},
	"bad type constraint name",
);

my $Int = $Any->create_child_type(
	constraint => sub { defined($_) and !ref($_) and $_ =~ /^[+-]?[0-9]+$/sm },
);

ok($Int->is_anon, "\$Int is anon");
is($Int->name, "__ANON__", "\$Int is called __ANON__");

ok(!$Int->can_be_inlined, '$Int cannot be inlined');

should_pass($_, $Int)
	for 1, -1, 0, 100, 10000, 987654;
should_fail($_, $Int)
	for 1.2, "Hello World", [], {}, undef, \*STDOUT;

ok_subtype($Any, $Int);
ok($Any->is_supertype_of($Int), 'Any is_supertype_of $Int');
ok($Int->is_a_type_of($Any), '$Int is_a_type_of Any');
ok($Int->is_a_type_of($Int), '$Int is_a_type_of $Int');
ok(!$Int->is_subtype_of($Int), 'not $Int is_subtype_of $Int');

my $Below = $Int->create_child_type(
	name => "Below",
	constraint_generator => sub {
		my $param = shift;
		return sub { $_ < $param };
	},
);

ok($Below->is_parameterizable, 'Below is_parameterizable');
ok(!$Below->is_parameterized, 'not Below is_parameterized');

should_pass($_, $Below)
	for 1, -1, 0, 100, 10000, 987654;
should_fail($_, $Below)
	for 1.2, "Hello World", [], {}, undef, \*STDOUT;

my $Below5 = $Below->parameterize(5);

ok($Below5->is_anon, '$Below5 is anon');
is($Below5->display_name, 'Below[5]', '... but still has a nice display name');

should_pass($_, $Below5)
	for 1, -1, 0;
should_fail($_, $Below5)
	for 1.2, "Hello World", [], {}, undef, \*STDOUT, 100, 10000, 987654;

ok_subtype($_, $Below5) for $Any, $Int, $Below;

ok($Below5->is_parameterized, 'Below[5] is_parameterized');
ok(!$Below->has_parameters, 'has_parameters method works - negative');
ok($Below5->has_parameters, 'has_parameters method works - positive');
is_deeply($Below5->parameters, [5], 'parameters method works');

my $Ref = "Type::Tiny"->new(
	name       => "Ref",
	constraint => sub {  ref($_)  },
	inlined    => sub { "ref($_)" },
);

my $ArrayRef = "Type::Tiny"->new(
	name       => "ArrayRef",
	parent     => $Ref,
	constraint => sub {         ref($_) eq 'ARRAY'  },
	inlined    => sub { undef, "ref($_) eq 'ARRAY'" },
);

is(
	$ArrayRef->inline_check('$xxx'),
	q[(((ref($xxx))) && (ref($xxx) eq 'ARRAY'))],
	'inlining stuff can return a list',
);

use Types::Standard ();

{
	my $subtype_of_Num = Types::Standard::Num->create_child_type;
	my $subtype_of_Int = Types::Standard::Int->create_child_type;
	
	ok(
		$subtype_of_Int->is_subtype_of( $subtype_of_Num ),
		'loose subtype comparison 1',
	);
	ok(
		! $subtype_of_Int->is_strictly_subtype_of( $subtype_of_Num ),
		'strict subtype comparison 1',
	);
	ok(
		$subtype_of_Num->is_supertype_of( $subtype_of_Int ),
		'loose supertype comparison 1',
	);
	ok(
		! $subtype_of_Num->is_strictly_supertype_of( $subtype_of_Int ),
		'strict supertype comparison 1',
	);
	
	ok(
		Types::Standard::Int->is_subtype_of( Types::Standard::Num ),
		'loose subtype comparison 2',
	);
	ok(
		Types::Standard::Int->is_strictly_subtype_of( Types::Standard::Num ),
		'strict subtype comparison 2',
	);
	ok(
		Types::Standard::Num->is_supertype_of( Types::Standard::Int ),
		'loose supertype comparison 2',
	);
	ok(
		Types::Standard::Num->is_strictly_supertype_of( Types::Standard::Int ),
		'strict supertype comparison 2',
	);
}

my $t1 = Types::Standard::Int;
my $t2 = $t1->create_child_type(name => 'T2');
my $t3 = $t2->create_child_type(name => 'T3');
my $t4 = $t3->create_child_type(name => 'T4');
my $t5 = $t4->create_child_type(name => 'T5');
my $t6 = $t5->create_child_type(name => 'T6');

my $found = $t6->find_parent(sub {
	$_->has_parent and $_->parent->name eq 'Int'
});

is($found->name, 'T2', 'find_parent (scalar context)');

my ($found2, $n2) = $t6->find_parent(sub {
	$_->has_parent and $_->parent->name eq 'Int'
});

is($found2->name, 'T2', 'find_parent (list context)');
is($n2, 4, '... includes a count');

my ($found3, $n3) = $t6->find_parent(sub { $_->name eq 'Kristoff' });

is($found3, undef, 'find_parent (null result)');
is($3, undef, '... includes an undef count');

{
	my $Any  = "Type::Tiny"->new(name => "Any");
	my $Blah = $Any->create_child_type->create_child_type(constraint => sub { "yes" });
	my $Bleh = $Blah->create_child_type(name => "Bleh")->create_child_type;
	
	is($Bleh->find_constraining_type->{uniq}, $Blah->{uniq}, 'find_constraining_type');
}
done_testing;
