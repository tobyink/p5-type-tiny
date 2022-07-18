=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny interacts nicely with Type::Library::Compiled-generated
libraries.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::Requires '5.008001';

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use CompiledLib qw( Int );
use Types::Standard qw( ArrayRef );
use Type::Params qw( compile );
use Type::Registry ();

my $ArrayOfInt = ArrayRef[ Int ];

isa_ok( $ArrayOfInt->type_parameter, 'Type::Tiny' );

ok   $ArrayOfInt->check( [ 1, 2, 3 ] );
ok ! $ArrayOfInt->check( [ "Nope!" ] );

{
	my $check;
	sub add_counts {
		$check ||= compile( Int, Int );
		my ( $x, $y ) = &$check;
		return $x + $y;
	}
}

is add_counts( 5, 6 ), 11;

my $e = exception {
	my $z = add_counts( 1.1, 2.2 );
};

like $e, qr/Value "1.1" did not pass type constraint "Int"/;

{
	local $@;
	my $r = eval q{
		package My::Lib;
		use Type::Library -extends => [ 'CompiledLib' ];
		1;
	};
	ok $r or diag explain( $@ );
}

isa_ok( My::Lib::Str(), 'Type::Tiny' );

my $reg = 'Type::Registry'->new;
$reg->add_types( 'CompiledLib' );
ok ! $reg->simple_lookup( 'InstanceOf' );
ok   $reg->simple_lookup( 'Int' );

done_testing;
