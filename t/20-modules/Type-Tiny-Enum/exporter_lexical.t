=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny::Enum can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Exporter::Tiny' => '1.006000' };

BEGIN {
	Exporter::Tiny::_HAS_NATIVE_LEXICAL_SUB or
	Exporter::Tiny::_HAS_MODULE_LEXICAL_SUB or
	plan skip_all => "This test requires Exporter::Tiny support for exporting lexical subs";
};

use Type::Tiny::Enum -lexical, Status => [ 'alive', 'dead' ];

isa_ok Status, 'Type::Tiny', 'Status';

ok is_Status( STATUS_DEAD );
ok is_Status( STATUS_ALIVE );

require Type::Registry;
ok( ! 'Type::Registry'->for_me->{'Status'}, 'nothing added to registry' );

ok( ! __PACKAGE__->can( $_ ), "no $_ function in symbol table" )
	for qw( Status is_Status assert_Status to_Status STATUS_DEAD STATUS_ALIVE );

done_testing;
