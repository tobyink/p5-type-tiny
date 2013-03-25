package BiggerLib;

use strict;
use warnings;

use Type::Library::Util;

use base "Type::Library";

extends "DemoLib";

declare "SmallInteger",
	as "Integer",
	where { $_ < 10 }
	message { "$_ is too big" };

declare "BigInteger",
	as "Integer",
	where { $_ >= 10 };

1;
