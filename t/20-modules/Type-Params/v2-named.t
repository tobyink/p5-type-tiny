=pod

=encoding utf-8

=head1 PURPOSE

Named parameter tests for modern Type::Params v2 API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires '5.020';
use Test::Fatal;

BEGIN {
	package Local::MyPackage;
	
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
		return $arg->arr->[ $arg->int ];
	}
	
	sub myfunc2 {
		state $signature = signature(
			method => 1,
			named  => [ arr => ArrayRef, int => Int ],
		);
		my ( $self, $arg ) = &$signature;
		
		return $arg->arr->[ $arg->int ];
	}
};

my $o   = bless {} => 'Local::MyPackage';
my @arr = ( 'a' .. 'z' );

is $o->myfunc( arr => \@arr, int => 2 ),  'c', 'myfunc (happy path)';
is $o->myfunc2( arr => \@arr, int => 4 ), 'e', 'myfunc2 (happy path)';

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
		$o->myfunc( arr => \@arr, int => 6, debug => undef );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc (param count exception)'
}

{
	my $e = exception {
		$o->myfunc2( arr => \@arr, int => 8, debug => undef );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc2 (param count exception)'
}

done_testing;
