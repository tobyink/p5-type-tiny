=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry works.

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
use Test::TypeTiny;
use Test::Fatal;

{
	package Local::Pkg1;
	use Type::Registry "t";
	
	::is(t(), Type::Registry->for_me, 'Type::Registry->for_me works');
	::is(t(), Type::Registry->for_class(__PACKAGE__), 'Type::Registry->for_class works');
	
	t->add_types(-Standard);
	
	::like(
		::exception { t->add_types(-MonkeyNutsAndChimpanzeeRaisins) },
		qr{^Types::MonkeyNutsAndChimpanzeeRaisins is not a type library},
		'cannot add non-existant type library to registry',
	);
	
	t->alias_type(Int => "Integer");
	
	::like(
		::exception { t->alias_type(ChimpanzeeRaisins => "ChimpSultanas") },
		qr{^Expected existing type constraint name},
		'cannot alias non-existant type in registry',
	);
	
	::ok(t->Integer == Types::Standard::Int(), 'alias works');
	::ok(t("Integer") == Types::Standard::Int(), 'alias works via simple_lookup');
	::ok(t("Integer[]") == Types::Standard::Int(), 'alias works via lookup');
}

{
	package Local::Pkg2;
	use Type::Registry "t";
	t->add_types(-Standard => [ -types => { -prefix => 'XYZ_' } ]);
	
	::ok(t->XYZ_Int == Types::Standard::Int(), 'prefix works');
}

ok(
	exception { Local::Pkg2::t->lookup("Integer") },
	'type registries are separate',
);

my $no_e = exception {
	do {
		my $obj = Type::Registry->new;
	};
	# DESTROY called
};

is($no_e, undef, 'DESTROY does not cause problems');

my $r = Type::Registry->for_class("Local::Pkg1");

should_pass([1, 2, 3], $r->lookup("ArrayRef[Integer]"));
should_fail([1, 2, 3.14159], $r->lookup("ArrayRef[Integer]"));

like(
	exception { $r->lookup('%foo') },
	qr{^Unexpected token in primary type expression; got '\%foo'},
	'type constraint invalid syntax',
);

like(
	exception { $r->lookup('MonkeyNuts') },
	qr{^MonkeyNuts is not a known type constraint },
	'type constraint unknown type',
);

like(
	exception { $r->MonkeyNuts },
	qr{^Can't locate object method "MonkeyNuts" via package},
	'type constraint unknown type (as method call)',
);

is(
	$r->lookup('MonkeyNuts::')->class,
	'MonkeyNuts',
	'class type',
);

require Type::Tiny::Enum;
$r->add_type('Type::Tiny::Enum'->new(values => [qw/Monkey Nuts/]), 'MonkeyNuts');
my $mn = $r->lookup('MonkeyNuts');
should_pass('Monkey', $mn);
should_pass('Nuts', $mn);
should_fail('Cashews', $mn);

use Type::Utils qw(dwim_type role_type class_type);

is(
	dwim_type('MonkeyNuts')->class,
	'MonkeyNuts',
	'DWIM - class type',
);

is(
	dwim_type('MonkeyNuts', does => 1)->role,
	'MonkeyNuts',
	'DWIM - role type',
);

is(
	dwim_type('ArrayRef[MonkeyNuts | Foo::]', does => 1)->inline_check('$X'),
	Types::Standard::ArrayRef()->parameterize(role_type({role=>"MonkeyNuts"}) | class_type({class=>"Foo"}))->inline_check('$X'),
	'DWIM - complex type',
);

my $reg = Type::Registry->new;
$reg->add_types(qw/ -Common::Numeric -Common::String /);
ok exists $reg->{'NonEmptyStr'};
ok exists $reg->{'PositiveInt'};

done_testing;
