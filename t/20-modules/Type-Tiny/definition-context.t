=pod

=encoding utf-8

=head1 PURPOSE

Checks the C<definition_context> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;

use Types::Common qw( -types t );
use Type::Utils;

# line 31 "definition-context.t"
declare 'SmallInt', as Int, where { $_ >= 0 and $_ < 10 };

is_deeply(
	t->SmallInt->definition_context,
	{
		'package' => 'main',
		'line'    => 31,
		'file'    => 'definition-context.t',
	},
	'expected definition context',
);

done_testing;
