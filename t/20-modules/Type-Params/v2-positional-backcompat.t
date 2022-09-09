
=encoding utf-8

=head1 PURPOSE

Positional parameter tests for modern Type::Params v2 API on Perl 5.8.

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
use Test::Fatal;

BEGIN {
	package Local::MyPackage;
	
	use strict;
	use warnings;
	
	use Types::Standard -types;
	use Type::Params -sigs;
	
	signature_for myfunc => (
		method => Object | Str,
		pos    => [ ArrayRef, Int ],
	);
	
	sub myfunc {
		my ( $self, $arr, $int ) = @_;
		return $arr->[$int];
	}
	
	my $signature;
	sub myfunc2 {
		$signature ||= signature(
			method => 1,
			pos    => [ ArrayRef, Int ],
		);
		my ( $self, $arr, $int ) = &$signature;
		
		return $arr->[$int];
	}
};

my $o   = bless {} => 'Local::MyPackage';
my @arr = ( 'a' .. 'z' );

is $o->myfunc( \@arr, 2 ),  'c', 'myfunc (happy path)';
is $o->myfunc2( \@arr, 4 ), 'e', 'myfunc2 (happy path)';

{
	my $e = exception {
		$o->myfunc( \@arr, undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc (type exception)'
}

{
	my $e = exception {
		$o->myfunc2( \@arr, undef );
	};
	like $e, qr/Undef did not pass type constraint "Int"/, 'myfunc2 (type exception)'
}

{
	my $e = exception {
		$o->myfunc( \@arr, 6, undef );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc (param count exception)'
}

{
	my $e = exception {
		$o->myfunc2( \@arr, 8, undef );
	};
	like $e, qr/Wrong number of parameters/, 'myfunc2 (param count exception)'
}

done_testing;
