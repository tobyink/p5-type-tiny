=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Type::Library> libraries work with Sub::Exporter plugins.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::Requires { "Sub::Exporter::Lexical" => "0.092291" };
use Test::More;
use Test::Fatal;

{
	use Sub::Exporter::Lexical qw( lexical_installer );
	use Types::Standard { installer => lexical_installer }, qw( ArrayRef );
	
	ArrayRef->( [] );
}
ok(!eval q{ ArrayRef->( [] ) }, 'the ArrayRef function was cleaned away');
ok(!__PACKAGE__->can("ArrayRef"), 'ArrayRef does not appear to be a method');

done_testing;
