use strict;
use warnings;
use Test::More;

{
	package MyTest;
	use Type::Utils 0.046 -all;
	use Type::Library 0.046
		-base,
		-declare => qw(TestDictionary SuperClassesList NameSpace);
	use Types::Standard 0.046 -types;
	
	declare NameSpace,
		as Str,
		where { $_ =~ /^[A-Za-z:]+$/ },
#		inline_as { undef, "$_ =~ /^[A-Za-z:]+\$/" },
		message { "-$_- does not match: " . qr/^[A-Za-z:]+$/ };
	
	declare SuperClassesList,
		as ArrayRef[ ClassName ],
#		inline_as { undef, "\@{$_} > 0" },
		where { scalar( @$_ ) > 0 };
	
	declare TestDictionary, as Dict[
		package      => Optional[ NameSpace ],
		superclasses => Optional[ SuperClassesList ],
	];
}

ok(
	MyTest::TestDictionary->check( { package => 'My::Package' } ),
	"Test TestDictionary"
);

#diag MyTest::TestDictionary->inline_check('$dict');

done_testing;
