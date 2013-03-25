package DemoLib;

use strict;
use warnings;

use Scalar::Util "looks_like_number";
use Type::Library::Util;

use base "Type::Library";

declare "String",
	where { not ref $_ }
	message { "is not a string" };

declare "Number",
	as "String",
	where { looks_like_number $_ },
	message { "'$_' doesn't look like a number" };

declare "Integer",
	as "Number",
	where { $_ eq int($_) };

1;
