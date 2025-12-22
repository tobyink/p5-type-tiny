=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry's behaviour when exporting lexically.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Exporter::Tiny ();
use Test::More;

BEGIN {
	plan skip_all => "Lexical exports unavailable in this environment"
		unless eval { Exporter::Tiny::_HAS_NATIVE_LEXICAL_SUB() || Exporter::Tiny::_HAS_MODULE_LEXICAL_SUB() };
};

use Type::Registry -lexical, t => { -as => 't1' };

{
	package Local::Foo;
	use Type::Registry -lexical, t => { -as => 't2' };
	use Type::Registry t => { -as => 't3' };
	
	use Scalar::Util qw( refaddr );
	
	::ok( refaddr(t1) != refaddr(t2) );
	::ok( refaddr(t1) != refaddr(t3) );
	::ok( refaddr(t2) != refaddr(t3) );
	
	t3->add_types( '-TypeTiny' );
	::ok( !t1->simple_lookup('ArrayLike') );
	::ok( !t2->simple_lookup('ArrayLike') );
	::ok(  t3->simple_lookup('ArrayLike') );
}

done_testing;