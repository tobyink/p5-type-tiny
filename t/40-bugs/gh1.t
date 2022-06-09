=pod

=encoding utf-8

=head1 PURPOSE

Test that subtypes of Type::Tiny::Class work.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/1>,
L<https://gist.github.com/rsimoes/5834506>.

=head1 AUTHOR

Richard Simões E<lt>rsimoes@cpan.orgE<gt>.

(Minor changes by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Richard Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Type::Utils;
use Math::BigFloat;
 
my $pc    = declare as class_type({ class => 'Math::BigFloat' }), where { 1 };
my $value = Math::BigFloat->new(0.5);

ok $pc->($value);

should_pass($value, $pc);
should_fail(0.5, $pc);

done_testing;
