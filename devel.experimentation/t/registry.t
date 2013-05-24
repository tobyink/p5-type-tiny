=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

{
	package Local::Pkg1;
	use Type::Registry "t";
	t->add_types(-Standard);
	t->alias_type(Int => "Integer");
	
	::ok(t->Integer == Types::Standard::Int(), 'alias works');
}

{
	package Local::Pkg2;
	use Type::Registry "t";
	t->add_types(-Standard => [ -types => { -prefix => 'XYZ_' } ]);
	
	::ok(t->XYZ_Int == Types::Standard::Int(), 'prefix works');
}

is(Local::Pkg2::t->lookup("Integer"), undef, 'type registries are separate');

my $r = Type::Registry->for_class("Local::Pkg1");

should_pass([1, 2, 3], $r->lookup("ArrayRef[Integer]"));
should_fail([1, 2, 3.14159], $r->lookup("ArrayRef[Integer]"));

done_testing;
