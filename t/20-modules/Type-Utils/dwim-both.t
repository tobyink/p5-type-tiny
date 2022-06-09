=pod

=encoding utf-8

=head1 PURPOSE

Checks sane behaviour of C<dwim_type> from L<Type::Utils> when both
Moose and Mouse are loaded.

=head1 DEPENDENCIES

Mouse 1.00 and Moose 2.0000; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
{ package AAA; use Test::Requires { "Mouse" => "1.00" } };
{ package BBB; use Test::Requires { "Moose" => "2.0000" } };

{
	package Minnie;
	use Mouse;
	use Mouse::Util::TypeConstraints qw(:all);
	subtype "FortyFive", as "Int", where { $_ == 40 or $_ == 5 };
}

{
	package Bulwinkle;
	use Moose;
	use Moose::Util::TypeConstraints qw(:all);
	subtype "FortyFive", as "Int", where { $_ == 45 };
}

use Test::TypeTiny;
use Type::Utils 0.015 qw(dwim_type);

my $mouse = dwim_type "FortyFive", for => "Minnie";
should_fail  2, $mouse;
should_pass  5, $mouse;
should_pass 40, $mouse;
should_fail 45, $mouse;
should_fail 99, $mouse;

my $moose = dwim_type "FortyFive", for => "Bulwinkle";
should_fail  2, $moose;
should_fail  5, $moose;
should_fail 40, $moose;
should_pass 45, $moose;
should_fail 99, $moose;

done_testing;
