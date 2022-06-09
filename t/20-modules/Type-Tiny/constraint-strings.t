=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works accepts strings of Perl code as constraints.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Types::Standard -types;
	
my $Str  = Str->where( 'length($_) > 0' );
my $Arr  = ArrayRef->where( '@$_ > 0' );
my $Hash = HashRef->where( 'keys(%$_) > 0' );

use Test::More;
use Test::Fatal;

is(
	exception { $Str->assert_valid( 'u' ) },
	undef,
	'non-empty string, okay',
);

isa_ok(
	exception { $Str->assert_valid( '' ) },
	'Error::TypeTiny',
	'result of empty string',
);

is(
	exception { $Arr->assert_valid( [undef] ) },
	undef,
	'non-empty arrayref, okay',
);

isa_ok(
	exception { $Arr->assert_valid( [] ) },
	'Error::TypeTiny',
	'result of empty arrayref',
);

is(
	exception { $Hash->assert_valid( { '' => undef } ) },
	undef,
	'non-empty hashref, okay',
);

isa_ok(
	exception { $Hash->assert_valid( +{} ) },
	'Error::TypeTiny',
	'result of empty hashref',
);

done_testing;
