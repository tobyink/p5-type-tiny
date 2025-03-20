=pod

=encoding utf-8

=head1 PURPOSE

Named parameter tests for modern Type::Params v2 API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires '5.020';
use Test::Fatal;
use Test::TypeTiny;
use Type::Params qw( ArgsObject );
use Types::Common qw( HashRef );

BEGIN {
	package Local::MyPackage;
	
	our $LAST;
	
	use strict;
	use warnings;
	
	use feature 'state';
	use experimental 'signatures';
	
	use Types::Standard -types;
	use Type::Params -sigs;
	
	signature_for myfunc => (
		method => Object | Str,
		named  => [ arr => ArrayRef, int => Int ],
	);
	
	sub myfunc ( $self, $arg ) {
		$LAST = $arg;
		return $arg->arr->[ $arg->int ];
	}
	
	sub myfunc2 {
		state $signature = signature(
			method => 1,
			named  => [ arr => ArrayRef, int => Int ],
		);
		my ( $self, $arg ) = &$signature;
		
		$LAST = $arg;
		return $arg->arr->[ $arg->int ];
	}
};

my $o   = bless {} => 'Local::MyPackage';
my @arr = ( 'a' .. 'z' );

{
	local $Local::MyPackage::LAST;
	is $o->myfunc( arr => \@arr, int => 2 ),  'c', 'myfunc (happy path)';
	should_pass $Local::MyPackage::LAST, $_ for ArgsObject, ArgsObject['Local::MyPackage::myfunc'];
	should_fail $Local::MyPackage::LAST, $_ for HashRef, ArgsObject['Local::MyPackage::myfunc2'];
}

{
	local $Local::MyPackage::LAST;
	is $o->myfunc2( arr => \@arr, int => 4 ), 'e', 'myfunc2 (happy path)';
	should_pass $Local::MyPackage::LAST, $_ for ArgsObject, ArgsObject['Local::MyPackage::myfunc2'];
	should_fail $Local::MyPackage::LAST, $_ for HashRef, ArgsObject['Local::MyPackage::myfunc'];
}

{
	my $e = exception {
		$o->myfunc( arr => \@arr, int => undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc (type exception)'
}

{
	my $e = exception {
		$o->myfunc2( arr => \@arr, int => undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc2 (type exception)'
}

{
	my $e = exception {
		$o->myfunc( arr => \@arr, int => 6, 'debug' );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc (param count exception)'
}

{
	my $e = exception {
		$o->myfunc2( arr => \@arr, int => 8, 'debug' );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc2 (param count exception)'
}

done_testing;
