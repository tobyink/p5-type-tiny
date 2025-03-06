=pod

=encoding utf-8

=head1 PURPOSE

Test C<signature_for_func> and C<signature_for_method> shortcuts.

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

use Types::Standard qw( Num ScalarRef );
use Type::Params qw( signature_for_func );

signature_for_func add_to_ref => (
	named         => [ ref => ScalarRef[Num], add => Num ],
	named_to_list => 1,
);

sub add_to_ref {
	my ( $ref, $add ) = @_;
	$$ref += $add;
}

{
	my $sum = 0;
	add_to_ref( ref => \$sum, add => 1 );
	add_to_ref( \$sum, 2 );
	add_to_ref( 3, \$sum );
	add_to_ref( 4, { -ref => \$sum } );
	is $sum, 10;
}

{
	package Local::Calculator;
	use Types::Standard qw( Num ScalarRef );
	use Type::Params qw( signature_for_method );
	
	sub new {
		my $class = shift;
		return bless {}, $class;
	}
	
	signature_for_method add_to_ref => (
		named         => [ ref => ScalarRef[Num], add => Num ],
		named_to_list => 1,
	);
	
	sub add_to_ref {
		my ( $self, $ref, $add ) = @_;
		$$ref += $add;
	}
}

{
	my $calc = Local::Calculator->new;
	my $sum = 0;
	$calc->add_to_ref( ref => \$sum, add => 1 );
	$calc->add_to_ref( \$sum, 2 );
	$calc->add_to_ref( 3, \$sum );
	$calc->add_to_ref( 4, { -ref => \$sum } );
	is $sum, 10;
}

done_testing;
