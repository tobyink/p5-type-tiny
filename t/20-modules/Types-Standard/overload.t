=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<Overload> from Types::Standard.

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
use Test::TypeTiny;

use Types::Standard qw( Any Item Defined Ref ArrayRef Object Overload );

my $o = bless [] => do {
	package Local::Class;
	use overload q[&] => sub { 1 }, fallback => 1;
	__PACKAGE__;
};

should_pass($o, Any);
should_pass($o, Item);
should_pass($o, Defined);
should_pass($o, Ref);
should_pass($o, Ref["ARRAY"]);
should_pass($o, Object);
should_pass($o, Overload);
should_pass($o, Overload["&"]);

should_fail($o, Ref["HASH"]);
should_fail($o, Overload["|"]);
should_fail("Local::Class", Overload);
should_fail([], Overload);

ok_subtype($_, Overload["&"])
	for Item, Defined, Ref, Object, Overload;

done_testing;
