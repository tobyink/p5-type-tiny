=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

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
	t->add_types(-Standard);
	t->alias_type(Int => "Integer");
	
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

is(
	$r->lookup('MonkeyNuts::')->class,
	'MonkeyNuts',
	'class type',
);

{
	package Type::Registry::DWIM;
	use base "Type::Registry";
	sub simple_lookup
	{
		my $self = shift;
		my $orig = $self->SUPER::simple_lookup(@_);
		return "Type::Tiny::Class"->new(class => $_[0]) if $_[1] && !$orig;
		return $orig;
	}
}

my $r2 = "Type::Registry::DWIM"->new;
$r2->add_types(-Standard);

is(
	$r2->lookup('MonkeyNuts')->class,
	'MonkeyNuts',
	'class type',
);

done_testing;
