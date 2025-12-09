=pod

=encoding utf-8

=head1 PURPOSE

Test the new C<check_coerce> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Types::Standard qw( Int Num );

my $EvenInt = Int
	->where( q{ $_ % 2 == 0 } )
	->plus_coercions( Num, q{ int($_) } );

is( $EvenInt->check_coerce(6), 6 );
is( $EvenInt->check_coerce(6.1), 6 );
is( $EvenInt->check_coerce(5), undef );
is( $EvenInt->check_coerce("Hi"), undef );

done_testing;
