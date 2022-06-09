=pod

=encoding utf-8

=head1 PURPOSE

Tests that types may be defined recursively.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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

#use B::Deparse;
#note( B::Deparse->new->coderef2text( \&MyTypes::is_MyHashRef ) );

BEGIN {
	package MyTypes2;
	
	use Type::Library -base, -declare => qw( StringArray StringHash StringContainer );
	use Types::Standard -types;
	
	__PACKAGE__->add_type(
		name    => StringArray,
		parent  => ArrayRef[ Str | StringArray | StringHash ],
	);
	
	__PACKAGE__->add_type(
		name    => StringHash,
		parent  => HashRef[ Str | StringArray | StringHash ],
	);
	
	__PACKAGE__->add_type(
		name    => StringContainer,
		parent  => StringHash | StringArray,
	);
	
	$INC{'MyTypes2.pm'} = __FILE__; # stop `use` from complaining
};

use MyTypes2 -types;

ok(   StringContainer->check({ foo => [], bar => ['a', 'b', { c => 'd' }], baz => 'e' }) );
ok( ! StringContainer->check({ foo => [], bar => ['a', 'b', { c => \42 }], baz => 'e' }) );

#use B::Deparse;
#note( B::Deparse->new->coderef2text( \&MyTypes2::is_StringContainer ) );

done_testing;
