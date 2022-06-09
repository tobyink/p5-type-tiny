=pod

=encoding utf-8

=head1 PURPOSE

Make sure that C<declare_coercion> works outside type libraries.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=92591>.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

Some additions by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL=> 'all';
use Test::More;

{
	package Local::TypeLib;
	
	use Type::Library -base;
	use Types::Standard -all;
	use Type::Utils -all;
	
	my $foo = declare_coercion to_type ArrayRef, from Any, via { [$_] };
	
	::is(
		$foo->type_constraint,
		'ArrayRef',
		"Type library, coercion target",
	);
	
	::is(
		$foo->type_coercion_map->[0],
		'Any',
		"Type library, coercion type map",
	);
}

{
	package Local::NotTypeLib;
	
	use Types::Standard -all;
	use Type::Utils -all;
	
	my $foo = declare_coercion to_type ArrayRef, from Any, via { [$_] };
	
	::is(
		$foo->type_constraint,
		'ArrayRef',
		"Not type library, coercion target",
	);
	
	::is(
		$foo->type_coercion_map->[0],
		'Any',
		"Not type library, coercion type map",
	);
}

done_testing;
