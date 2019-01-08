=pod

=encoding utf-8

=head1 PURPOSE

Possible issue causing segfaults on threaded Perl 5.18.x.

=head1 AUTHOR

Graham Knop E<lt>haarg@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2019 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Config;
BEGIN {
	plan skip_all => "your perl does not support ithreads"
		unless $Config{useithreads};
};

(my $script = __FILE__) =~ s/t\z/pl/;

for (1..100)
{
	my $out = system $^X, (map {; '-I', $_ } @INC), $script;
	is($out, 0);
}

done_testing;
