=pod

=encoding utf-8

=head1 PURPOSE

Test C<compile> and C<compile_named> support autocloned parameters.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Test::Requires 'Storable';
use Test::Fatal;
use Types::Standard -types;
use Type::Params qw( compile compile_named );
use Scalar::Util qw( refaddr );

my $arr = [];

{
	my $check = compile( ArrayRef, { clone => 0 } );
	my ( $got ) = $check->( $arr );
	is( refaddr( $got ), refaddr( $arr ), 'compile with clone => 0' );
}

{
	my $check = compile( ArrayRef, { clone => 1 } );
	my ( $got ) = $check->( $arr );
	isnt( refaddr( $got ), refaddr( $arr ), 'compile with clone => 1' );
}

{
	my $check = compile_named( xxx => ArrayRef, { clone => 0 } );
	my ( $got ) = $check->( xxx => $arr );
	is( refaddr( $got->{xxx} ), refaddr( $arr ), 'compile_named with clone => 0' );
}

{
	my $check = compile_named( xxx => ArrayRef, { clone => 1 } );
	my ( $got ) = $check->( xxx => $arr );
	isnt( refaddr( $got->{xxx} ), refaddr( $arr ), 'compile_named with clone => 1' );
}

done_testing;
