=pod

=encoding utf-8

=head1 PURPOSE

Possible issue causing segfaults on threaded Perl 5.18.x.

=head1 AUTHOR

Graham Knop E<lt>haarg@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Config;
BEGIN {
	if ( $] < 5.020
	and  defined $ENV{RUNNER_OS}
	and  $ENV{RUNNER_OS} =~ /windows/i ) {
		plan skip_all => "skipping on CI due to known issues!";
	}
	elsif ( not $Config{useithreads} ) {
		plan skip_all => "ithreads only test";
	}
};

(my $script = __FILE__) =~ s/t\z/pl/;

for (1..100)
{
	my $out = system $^X, (map {; '-I', $_ } @INC), $script;
	is($out, 0);
}

done_testing;
