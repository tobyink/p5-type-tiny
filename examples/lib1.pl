use strict;
use warnings;

BEGIN {
	package Local::TypeLib; no thanks;
	
	use Type::Utils;
	use Data::Dumper;
	use Scalar::Util "looks_like_number";
	
	use base "Type::Library";
	
	declare "String",
		where { not ref $_ };
	
	declare "Number",
		as "String",
		where { looks_like_number $_ };

	declare "Integer",
		as "Number",
		where { $_ eq int($_) };
};

{
	package Foo;
	use Moose;
	use Local::TypeLib -moose, qw(Integer);
	has fff => (is => "ro", isa => Integer);
}

Foo->new(fff => 5.1);
