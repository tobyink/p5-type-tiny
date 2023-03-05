use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Type::Tiny::Bitfield;
use Types::Common qw( ArrayRef );

like(
	exception {
		Type::Tiny::Bitfield->new( parent => ArrayRef, values => {} ),
	},
	qr/cannot have a parent constraint passed to the constructor/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new( constraint => sub { 0 }, values => {} ),
	},
	qr/cannot have a constraint coderef passed to the constructor/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new( inlined => sub { 0 }, values => {} ),
	},
	qr/cannot have a inlining coderef passed to the constructor/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new(),
	},
	qr/Need to supply hashref of values/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new( values => { foo => 2 } ),
	},
	qr/Not an all-caps name in a bitfield/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new( values => { FOO => 3 } ),
	},
	qr/Not a positive power of 2 in a bitfield/i,
);

like(
	exception {
		Type::Tiny::Bitfield->new( values => { FOO => 1, BAR => 1 } ),
	},
	qr/Duplicate value in a bitfield/i,
);

done_testing;
