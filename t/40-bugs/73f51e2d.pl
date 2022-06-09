=pod

=encoding utf-8

=head1 PURPOSE

Helper file for C<< 73f51e2d.t >>.

=head1 AUTHOR

Graham Knop E<lt>haarg@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use threads;
use strict;
use warnings;
use Type::Tiny;

my $int = Type::Tiny->new(
	name       => "Integer",
	constraint => sub { /^(?:-?[1-9][0-9]*|0)$|/ },
	message    => sub { "$_ isn't an integer" },
);

threads->create(sub {
	my $type = $int;
	1;
})->join;
