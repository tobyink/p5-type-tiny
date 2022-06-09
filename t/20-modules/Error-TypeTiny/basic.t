=pod

=encoding utf-8

=head1 PURPOSE

Tests for basic L<Error::TypeTiny> functionality.

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

use Test::More;
use Test::Fatal;
use Error::TypeTiny;

#line 31 "basic.t"
my $e1 = exception { 'Error::TypeTiny'->throw() };

is($e1->message, 'An exception has occurred', '$e1->message (default)');
is($e1->context->{package}, 'main', '$e1->context->{main}');
is($e1->context->{line}, '31', '$e1->contex1t->{line}');
is($e1->context->{file}, 'basic.t', '$e1->context->{file}');

my $e2 = exception { 'Error::TypeTiny'->throw(message => 'oh dear') };

is($e2->message, 'oh dear', '$e2->message');

my $e3 = exception { Error::TypeTiny::croak('oh %s', 'drat') };

is($e3->message, 'oh drat', '$e3->message (set by croak)');

done_testing;
