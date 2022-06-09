=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<FileHandle> from Types::Standard.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/38>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Test::Requires qw( IO::String );

use Types::Standard qw( FileHandle );

should_pass('IO::String'->new, FileHandle);
should_fail('IO::String', FileHandle);

done_testing;
