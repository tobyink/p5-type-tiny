=pod

=encoding utf-8

=head1 PURPOSE

Test L<Types::TypeTiny::to_TypeTiny> pseudo-coercion and the
L<Types::TypeTiny::_ForeignTypeConstraint> type.

=head1 DEPENDENCIES

This test requires L<Moose> 2.0000, L<Mouse> 1.00, and L<Moo> 1.000000.
Otherwise, it is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

# Test::Requires calls ->import on Moose/Mouse, so be sure
# to import them into dummy packages.
{ package XXX; use Test::Requires { Moose => '2.0000' } };
{ package YYY; use Test::Requires { Mouse => '1.00' } };
{ package ZZZ; use Test::Requires { Moo   => '1.000000' } };

use Test::More;
use Test::TypeTiny -all;
use Types::TypeTiny -all;
use Types::Standard qw(Int);
use Moose::Util::TypeConstraints qw(find_type_constraint);

ok(TypeTiny->has_coercion, "TypeTiny->has_coercion");

subtest "Coercion from built-in Moose type constraint object" => sub
{
	my $orig = find_type_constraint("Int");
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted a Moose type constraint to a Type::Tiny one');
	is($type->name, 'Int', '... which has the correct name');
	ok($type->can_be_inlined, '... and which can be inlined');
	note $type->inline_check('$X');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};

#	This doesn't provide the same message because Type::Tiny isn't
#	really coercing a Moose type constraint, it's just grabbing `Int`
#	from Types::Standard.
#	
#	is(
#		$type->get_message(3.3),
#		$orig->get_message(3.3),
#		'... and provides proper message',
#	);
};

subtest "Coercion from custom Moose type constraint object" => sub
{
	my $orig = 'Moose::Meta::TypeConstraint'->new(
		name => 'EvenInt',
		parent => find_type_constraint("Int"),
		constraint => sub {
			my ( $value ) = @_;
			$value % 2 == 0;
		},
		inlined => sub {
			my ( $self, $var ) = @_;
			return sprintf(
				'do { %s } && !( %s %% 2 )',
				$self->parent->_inline_check( $var ),
				$var,
			);
		},
		message => sub {
			my ( $value ) = @_;
			return find_type_constraint("Int")->check( $value )
				? "$value isn't an integer at all"
				: "$value is odd";
		},
	);
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted a Moose type constraint to a Type::Tiny one');
	is($type->display_name, 'EvenInt', '... which has the correct display_name');
	ok($type->can_be_inlined, '... and which can be inlined');
	note $type->inline_check('$X');
	subtest "... and it works" => sub
	{
		should_fail(3.3, $type);
		should_fail(123, $type);
		should_pass(124, $type);
	};

	is(
		$type->get_message(3.3),
		$orig->get_message(3.3),
		'... and provides proper message',
	);
};

my %moose_ptype_opts = (
	name    => 'ArrayOrHashRef',
	parent  => find_type_constraint('Ref'),
	constraint => sub {
		my $value = @_ ? pop : $_;
		ref($value) eq 'HASH' or ref($value) eq 'ARRAY';
	},
	constraint_generator => sub {
		my $param = shift;
		return sub {
			my $value = @_ ? pop : $_;
			if (ref($value) eq 'ARRAY') {
				($param->check($_) or return) for @$value;
				return 1;
			}
			elsif (ref($value) eq 'HASH') {
				($param->check($_) or return) for values %$value;
				return 1;
			}
			return;
		};
	},
);

my $ptype_tests = sub {
	my $moose = Moose::Meta::TypeConstraint::Parameterizable->new(%moose_ptype_opts);
	
	# wow, the Moose API is stupid; need to do this
	Moose::Util::TypeConstraints::register_type_constraint($moose);
	Moose::Util::TypeConstraints::add_parameterizable_type($moose);
	
	note "Moose native type, no parameters";
	ok( $moose->check([]) );
	ok( $moose->check({}) );
	ok( $moose->check([1..10]) );
	ok( $moose->check({foo => 1, bar => 2}) );
	ok( $moose->check(['hello world']) );
	ok( ! $moose->check(\1) );
	ok( ! $moose->check(42) );
	
	note "Moose native type, parameterized with Moose type";
	my $moose_with_moose = $moose->parameterize( find_type_constraint('Int') );
	ok( $moose_with_moose->check([]) );
	ok( $moose_with_moose->check({}) );
	ok( $moose_with_moose->check([1..10]) );
	ok( $moose_with_moose->check({foo => 1, bar => 2}) );
	ok( ! $moose_with_moose->check(['hello world']) );
	ok( ! $moose_with_moose->check(\1) );
	ok( ! $moose_with_moose->check(42) );
	
	note "Moose native type, parameterized with TT type";
	my $moose_with_tt = $moose->parameterize( Int );
	ok( $moose_with_tt->check([]) );
	ok( $moose_with_tt->check({}) );
	ok( $moose_with_tt->check([1..10]) );
	ok( $moose_with_tt->check({foo => 1, bar => 2}) );
	ok( ! $moose_with_tt->check(['hello world']) );
	ok( ! $moose_with_tt->check(\1) );
	ok( ! $moose_with_tt->check(42) );
	
	note 'TT type, no parameters';
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	isa_ok($tt, 'Type::Tiny');
	is($tt->display_name, $moose_ptype_opts{name});
	should_pass([], $tt);
	should_pass({}, $tt);
	should_pass([1..10], $tt);
	should_pass({foo => 1, bar => 2}, $tt);
	should_pass(['hello world'], $tt);
	should_fail(\1, $tt);
	should_fail(42, $tt);
	
	note 'TT type, parameterized with Moose type';
	my $tt_with_moose = $tt->of( find_type_constraint('Int') );
	should_pass([], $tt_with_moose);
	should_pass({}, $tt_with_moose);
	should_pass([1..10], $tt_with_moose);
	should_pass({foo => 1, bar => 2}, $tt_with_moose);
	should_fail(['hello world'], $tt_with_moose);
	should_fail(\1, $tt_with_moose);
	should_fail(42, $tt_with_moose);

	note 'TT type, parameterized with TT type';
	my $tt_with_tt = $tt->of( Int );
	should_pass([], $tt_with_tt);
	should_pass({}, $tt_with_tt);
	should_pass([1..10], $tt_with_tt);
	should_pass({foo => 1, bar => 2}, $tt_with_tt);
	should_fail(['hello world'], $tt_with_tt);
	should_fail(\1, $tt_with_tt);
	should_fail(42, $tt_with_tt);
	
	return (
		$moose,
		$moose_with_moose,
		$moose_with_tt,
		$tt,
		$tt_with_moose,
		$tt_with_tt,
	);
};

subtest "Coercion from Moose parameterizable type constraint object" => sub {
	$ptype_tests->();
};

# Moose cannot handle two parameterizable types sharing a name
$moose_ptype_opts{name} .= '2';

$moose_ptype_opts{inlined} = sub {
	my $var = pop;
	sprintf('ref(%s) =~ /^(HASH|ARRAY)$/', $var);
};

$moose_ptype_opts{inline_generator} = sub {
	my ($base, $param, $var) = @_;
	
	my $code = sprintf qq{do{
		if (ref($var) eq 'ARRAY') {
			my \$okay = 1;
			(%s or ((\$okay=0), last)) for \@{$var};
			\$okay;
		}
		elsif (ref($var) eq 'HASH') {
			my \$okay = 1;
			(%s or ((\$okay=0), last)) for values %%{$var};
			\$okay;
		}
		else {
			0;
		}
	}}, ($param->_inline_check('$_')) x 2;
	
	$code;
};

subtest "Coercion from Moose parameterizable type constraint object with inlining" => sub
{
	my @types = $ptype_tests->();
	
	note 'check everything can be inlined';
	for my $type (@types) {
		ok( $type->can_be_inlined );
		ok( length($type->_inline_check('$xxx')) );
	}
	
	note( $types[-1]->inline_check('$VALUE') );
};

subtest "Coercion from Moose enum type constraint" => sub {
	my $moose = Moose::Util::TypeConstraints::enum(Foo => [qw/ foo bar baz /]);
	ok(   $moose->check("foo") );
	ok( ! $moose->check("quux") );
	ok( ! $moose->check(\1) );
	ok( ! $moose->check(undef) );
	
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	ok(   $tt->check("foo") );
	ok( ! $tt->check("quux") );
	ok( ! $tt->check(\1) );
	ok( ! $tt->check(undef) );
	
	isa_ok($tt, 'Type::Tiny::Enum');
	is_deeply($tt->values, $moose->values);
	ok $tt->can_be_inlined;
	note( $tt->inline_check('$STR') );
};

subtest "Coercion from Moose class type constraint" => sub {
	my $moose = Moose::Util::TypeConstraints::class_type(FooObj => { class => 'MyApp::Foo' });
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	isa_ok($tt, 'Type::Tiny::Class');
	is($tt->class, $moose->class);
	ok $tt->can_be_inlined;
	note( $tt->inline_check('$OBJECT') );
};

subtest "Coercion from Moose role type constraint" => sub {
	my $moose = Moose::Util::TypeConstraints::role_type(DoesFoo => { role => 'MyApp::Foo' });
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	isa_ok($tt, 'Type::Tiny::Role');
	is($tt->role, $moose->role);
	ok $tt->can_be_inlined;
	note( $tt->inline_check('$OBJECT') );
};

subtest "Coercion from Moose duck type constraint" => sub {
	my $moose = Moose::Util::TypeConstraints::duck_type(FooInterface => [qw/foo bar baz/]);
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	isa_ok($tt, 'Type::Tiny::Duck');
	is_deeply([ sort @{$tt->methods} ], [ sort @{$moose->methods} ]);
	ok $tt->can_be_inlined;
	note( $tt->inline_check('$OBJECT') );
};

subtest "Coercion from Moose union type constraint" => sub {
	my $moose = Moose::Util::TypeConstraints::union(
		'ContainerThang',
		[ find_type_constraint('ArrayRef'), find_type_constraint('HashRef'), ]
	);
	my $tt    = Types::TypeTiny::to_TypeTiny($moose);
	is($tt->display_name, 'ContainerThang');
	isa_ok($tt, 'Type::Tiny::Union');
	ok($tt->[0] == Types::Standard::ArrayRef);
	ok($tt->[1] == Types::Standard::HashRef);
	ok $tt->can_be_inlined;
	note( $tt->inline_check('$REF') );
};


subtest "Coercion from Mouse type constraint object" => sub
{
	my $orig = Mouse::Util::TypeConstraints::find_type_constraint("Int");
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted a Mouse type constraint to a Type::Tiny one');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
	is(
		$type->get_message(3.3),
		$orig->get_message(3.3),
		'... and provides proper message',
	);
};

subtest "Coercion from predicate-like coderef" => sub
{
	my $orig = sub { $_[0] =~ /\A-?[0-9]+\z/ };
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
};

subtest "Coercion from assertion-like coderef" => sub
{
	my $orig = sub { $_[0] =~ /\A-?[0-9]+\z/ or die("not an integer") };
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
	like(
		$type->validate(3.3),
		qr/\Anot an integer/,
		'... and provides proper message',
	);
};

subtest "Coercion from Sub::Quote coderef" => sub
{
	require Sub::Quote;
	my $orig = Sub::Quote::quote_sub(q{ $_[0] =~ /\A-?[0-9]+\z/ });
	my $type = to_TypeTiny $orig;
	
	should_pass($orig, _ForeignTypeConstraint);
	should_fail($type, _ForeignTypeConstraint);
	
	should_pass($type, TypeTiny, 'to_TypeTiny converted the coderef to a Type::Tiny object');
	ok($type->can_be_inlined, '... which can be inlined');
	note $type->inline_check('$X');
	subtest "... and it works" => sub
	{
		should_pass(123, $type);
		should_fail(3.3, $type);
	};
};

done_testing;
