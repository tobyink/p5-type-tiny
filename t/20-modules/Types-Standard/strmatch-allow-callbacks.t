=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<StrMatch> from Types::Standard
when C<< $Type::Tiny::AvoidCallbacks >> is false.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );
use Test::More;
use Test::Requires '5.020';

use Types::Standard 'StrMatch';

BEGIN { eval q{ use Test::Warnings } unless "$^V" =~ /c$/ };

$Type::Tiny::AvoidCallbacks = 0;

my $z;
my $complex = StrMatch->of(qr/x(?{$z})/);  # closure so can't be easily inlined
ok($complex->can_be_inlined, "using callbacks, this complex regexp can be inlined");
like($complex->inline_check('$_'), qr/Types::Standard::StrMatch/, '... and looks okay');

done_testing;
