=pod

=encoding utf-8

=head1 PURPOSE

Checks the C<Type::Tiny::Class>'s C<plus_constructors> method.

=head1 DEPENDENCIES

Requires Moose 2.00; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );
use utf8;

use Test::More;
use Test::Requires { Moose => 2.00 };
use Test::TypeTiny;

my ($Address, $Person);

BEGIN {
	package Address;
	
	use Moose;
	use Types::Standard qw( Str );
	use Type::Utils;
	
	has [qw/ line1 line2 town county postcode country /] => (
		is       => "ro",
		isa      => Str,
	);
	
	sub _new_from_array
	{
		my $class = shift;
		my @addr  = ref($_[0]) ? @{$_[0]} : @_;
		$class->new(
			line1     => $addr[0],
			line2     => $addr[1],
			town      => $addr[2],
			county    => $addr[3],
			postcode  => $addr[4],
			country   => $addr[5],
		);
	}
	
	$Address = class_type { class => __PACKAGE__ };
};

BEGIN {
	package Person;
	
	use Moose;
	use Types::Standard qw( Str Join Tuple HashRef );
	use Type::Utils;
	
	has name => (
		required => 1,
		coerce   => 1,
		is       => "ro",
		isa      => Str->plus_coercions(Join[" "]),
	);
	
	has addr => (
		coerce   => 1,
		is       => "ro",
		isa      => $Address->plus_constructors(
			(Tuple[(Str) x 6]) => "_new_from_array",
			(HashRef)          => "new",
		),
	);
	
	sub _new_from_name
	{
		my $class = shift;
		my ($name) = @_;
		$class->new(name => $name);
	}
	
	$Person = class_type { class => __PACKAGE__ };
};

ok(
	"Person"->meta->get_attribute("addr")->type_constraint->is_a_type_of($Address),
	q["Person"->meta->get_attribute("addr")->type_constraint->is_a_type_of($Address)],
);

my $me = Person->new(
	name   => ["Toby", "Inkster"],
	addr   => ["Flat 2, 39 Hartington Road", "West Ealing", "LONDON", "", "W13 8QL", "United Kingdom"],
);

my $me2 = Person->new(
	name   => "Toby Inkster",
	addr   => Address->new(
		line1     => "Flat 2, 39 Hartington Road",
		line2     => "West Ealing",
		town      => "LONDON",
		county    => "",
		postcode  => "W13 8QL",
		country   => "United Kingdom",
	),
);

is_deeply($me, $me2, 'coercion worked');

my $you = $Person->plus_constructors->coerce({ name => "Livvy" });
my $you2 = Person->new(name => "Livvy");
is_deeply($you, $you2, 'coercion worked (plus_constructors with no parameters)');

done_testing;
