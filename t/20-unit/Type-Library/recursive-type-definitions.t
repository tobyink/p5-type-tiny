use strict;
use warnings;
use Test::More;

BEGIN {
	package MyTypes;
	
	use Type::Library -base, -declare => 'MyHashRef';
	use Types::Standard -types;
	
	__PACKAGE__->add_type(
		name    => MyHashRef,
		parent  => HashRef[ Int | MyHashRef ],
	);
	
	$INC{'MyTypes.pm'} = __FILE__; # stop `use` from complaining
};

use MyTypes -types;

my %good1 = ( foo => 1, bar => 2 );
my %good2 = ( %good1, bat => {}, baz => { foo => 3 } );
my %good3 = ( %good2, quux => { quuux => { quuuux => 0, xyzzy => {} } } );

my %bad1 = ( %good1, bar => \1 );
my %bad2 = ( %good2, baz => { foo => \1 } );
my %bad3 = ( %good3, quux => { quuux => { quuuux => 0, xyzzy => \1 } } );

ok( MyHashRef->can_be_inlined );

ok( MyHashRef->check( {} ) );
ok( MyHashRef->check( \%good1 ) );
ok( MyHashRef->check( \%good2 ) );
ok( MyHashRef->check( \%good3 ) );
ok( ! MyHashRef->check( \%bad1 ) );
ok( ! MyHashRef->check( \%bad2 ) );
ok( ! MyHashRef->check( \%bad3 ) );
ok( ! MyHashRef->check( undef ) );
ok( ! MyHashRef->check( \1 ) );

use B::Deparse;
note( B::Deparse->new->coderef2text( \&MyTypes::is_MyHashRef ) );

done_testing;
