=pod

=encoding utf-8

=head1 PURPOSE

Check the Type::Registrys can have parents.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Test::Fatal;

use Types::Standard;

{
	package Local::Pkg1;
	use Type::Registry "t";
	t->add_type(Types::Standard::Int);
	t->alias_type( 'Int' => 'Integer' );
}

{
	package Local::Pkg2;
	use Type::Registry "t";
	t->add_type(Types::Standard::ArrayRef);
	t->alias_type( 'ArrayRef' => 'List' );
	t->set_parent( 'Local::Pkg1' );
}

my $reg  = Type::Registry->for_class('Local::Pkg2');
my $type = $reg->lookup('List[Integer]');

should_pass([1,2,3], $type);
should_fail([1,2,3.1], $type);

$reg->clear_parent;

ok ! $reg->get_parent;

my $e = exception {
	$reg->lookup('List[Integer]');
};

like( $e, qr/Integer is not a known type constraint/, 'after clearing parent, do not know parent registry types' );

done_testing;
