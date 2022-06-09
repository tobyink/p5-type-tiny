=pod

=encoding utf-8

=head1 PURPOSE

Check that Specio type libraries can be extended by Type::Library.

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
use Test::TypeTiny;
use Test::Requires 'Specio::Library::Builtins';

BEGIN {
	package Local::MyTypes;
	use Type::Library -base;
	use Type::Utils;
	Type::Utils::extends 'Specio::Library::Builtins';
	$INC{'Local/MyTypes.pm'} = __FILE__;  # allow `use` to work
};

use Local::MyTypes qw(Int ArrayRef);

should_pass 1, Int;
should_pass [], ArrayRef;
should_fail 1, ArrayRef;
should_fail [], Int;

done_testing;
