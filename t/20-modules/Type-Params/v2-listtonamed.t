=pod

=encoding utf-8

=head1 PURPOSE

Test list_to_named option for Type::Params.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Types::Standard qw( Int ScalarRef );
use Type::Params qw( signature_for );

signature_for test1 => (
	named         => [ foo => Int, bar => Int ],
	list_to_named => !!1,
	oo_trace      => !!0,
);

sub test1 {
	my $args = shift;
	return +{%$args};
}

is_deeply( test1( foo => 3, bar => 4 ), { foo => 3, bar => 4 } );
is_deeply( test1( bar => 4, foo => 3 ), { foo => 3, bar => 4 } );
is_deeply( test1( { foo => 3, bar => 4 } ), { foo => 3, bar => 4 } );
is_deeply( test1( { bar => 4, foo => 3 } ), { foo => 3, bar => 4 } );

is_deeply( test1( 3, bar => 4 ), { foo => 3, bar => 4 } );
is_deeply( test1( 3, { bar => 4 } ), { foo => 3, bar => 4 } );

is_deeply( test1( 4, foo => 3 ), { foo => 3, bar => 4 } );
is_deeply( test1( 4, { foo => 3 } ), { foo => 3, bar => 4 } );

is_deeply( test1( 3, 4 ), { foo => 3, bar => 4 } );

like exception { test1( 3, { foo => 1, bar => 4 } ) }, qr/^Superfluous positional arguments/;
like exception { test1( 3, foo => 1, bar => 4 ) }, qr/^Superfluous positional arguments/;

signature_for test2 => (
	named         => [ foo => Int, bar => ScalarRef ],
	list_to_named => !!1,
	oo_trace      => !!0,
);

sub test2 {
	my $args = shift;
	return +{%$args};
}

is_deeply( test2( \3, 4 ), { foo => 4, bar => \3 } );
is_deeply( test2( 3, \4 ), { foo => 3, bar => \4 } );
is_deeply( test2( \3, foo => 4 ), { foo => 4, bar => \3 } );
is_deeply( test2( 3, bar => \4 ), { foo => 3, bar => \4 } );

signature_for test3 => (
	named         => [ foo => Int, bar => ScalarRef, { in_list => 0 } ],
	list_to_named => !!1,
	oo_trace      => !!0,
);

sub test3 {
	my $args = shift;
	return +{%$args};
}

is_deeply( test3( 3, bar => \4 ), { foo => 3, bar => \4 } );
like exception { test3( 3, \4 ) }, qr/Missing required parameter/;

done_testing;
