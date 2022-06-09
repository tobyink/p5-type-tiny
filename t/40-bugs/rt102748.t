=pod

=encoding utf-8

=head1 PURPOSE

Tests inheriting from a MooseX::Types library that uses
L<MooseX::Types::Parameterizable> and
L<MooseX::Meta::TypeCoercion::Parameterizable>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=102748>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
{ package Local::XYZ1; use Test::Requires 'MooseX::Types'; }
{ package Local::XYZ2; use Test::Requires 'MooseX::Types::DBIx::Class'; }

my $e = exception {
	package MyApp::Types;
	use namespace::autoclean;
	use Type::Library -base;
	use Type::Utils 'extends';
	extends 'MooseX::Types::DBIx::Class';
};

is($e, undef);
done_testing;
