=pod

=encoding utf-8

=head1 PURPOSE

Checks the C<use_eq> attribute of Type::Tiny::Enum

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# Force Type::Tiny::XS to not be used
BEGIN {
	$ENV{PERL_TYPE_TINY_XS} = 0;
};

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Type::Tiny::Enum;

my $ExplicitUseRE    = Type::Tiny::Enum->new( use_eq => 0, values => [qw/ foo bar1 /] );
my $ExplicitUseEq    = Type::Tiny::Enum->new( use_eq => 1, values => [qw/ foo bar1 bar2 bar3 bar4 bar5 /] );
my $ImplicitUseRE    = Type::Tiny::Enum->new(              values => [qw/ foo bar1 bar2 bar3 bar4 bar5 /] );
my $ImplicitUseEq    = Type::Tiny::Enum->new(              values => [qw/ foo bar1 /] );

ok !$ExplicitUseRE->use_eq, 'accessor for explicit use_eq=>false';
ok  $ExplicitUseEq->use_eq, 'accessor for explicit use_eq=>true';
ok !$ImplicitUseRE->use_eq, 'accessor for defaulted use_eq=>false';
ok  $ImplicitUseEq->use_eq, 'accessor for defaulted use_eq=>true';

like $ExplicitUseRE->inline_check('$VAR'), qr/\$VAR\s*=~/, 'explicit use_eq=>false seems to generate correct code';
like $ExplicitUseEq->inline_check('$VAR'), qr/\$VAR\s*eq/, 'explicit use_eq=>true seems to generate correct code';
like $ImplicitUseRE->inline_check('$VAR'), qr/\$VAR\s*=~/, 'defaulted use_eq=>false seems to generate correct code';
like $ImplicitUseEq->inline_check('$VAR'), qr/\$VAR\s*eq/, 'defaulted use_eq=>true seems to generate correct code';

should_pass $_, $ExplicitUseRE for 'foo', 'bar1';
should_fail $_, $ExplicitUseRE for 'foo1', 'bar2', undef, [];

should_pass $_, $ExplicitUseEq for 'foo', 'bar1', 'bar2';
should_fail $_, $ExplicitUseEq for 'foo1', undef, [];

should_pass $_, $ImplicitUseEq for 'foo', 'bar1';
should_fail $_, $ImplicitUseEq for 'foo1', 'bar2', undef, [];

should_pass $_, $ImplicitUseRE for 'foo', 'bar1', 'bar2';
should_fail $_, $ImplicitUseRE for 'foo1', undef, [];

done_testing;
