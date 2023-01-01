=pod

=encoding utf-8

=head1 PURPOSE

Tests type libraries can detect two types trying to export the same functions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;

my $e = do {
	package My::Types;
	use Type::Library -base, -utils;
	
	# This should create constants ABC_DEF_GHI and ABC_DEF_JKL
	enum( 'Abc_Def', [qw/ ghi jkl /] );
	
	local $@;
	eval {
		# This should also create constant ABC_DEF_GHI
		enum( 'Abc', [qw/ def_ghi /] );
		1;
	};
	$@;
};

like $e, qr/Function ABC_DEF_GHI is provided by types Abc_Def and Abc/;

done_testing;
