=pod

=encoding utf-8

=head1 PURPOSE

Tests for deep coercion.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=104154>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Type::Tiny;
use Test::More;

my $type_without = "Type::Tiny"->new(
	name       => "HasParam_without",
	message    => sub { "$_ ain't got a number" },
	constraint_generator => sub { sub { 0 } }, # Reject everything
	deep_explanation => sub { ["love to contradict"] },
);

my $type_with = "Type::Tiny"->new(
	constraint => sub { 1 }, # Un-parameterized accepts al
	name       => "HasParam_with",
	message    => sub { "$_ ain't got a number" },
	constraint_generator => sub { sub { 0 } }, # Reject everything
	deep_explanation => sub { ["love to contradict"] },
);

my $type_parent = "Type::Tiny"->new(
	parent => $type_without,
	name       => "HasParam_parent",
	message    => sub { "$_ ain't got a number" },
	constraint_generator => sub { sub { 0 } }, # Reject everything
	deep_explanation => sub { ["love to contradict"] },
);

my $s = 'a string';
my $param_with = $type_with->parameterize('an ignored parameter');
my $param_parent = $type_parent->parameterize('an ignored parameter');
my $param_without = $type_without->parameterize('an ignored parameter');

my $explain_with=join("\n  ",@{$param_with->validate_explain($s,'$s')});
my $explain_parent=join("\n  ",@{$param_parent->validate_explain($s,'$s')});
my $explain_without=join("\n  ",@{$param_without->validate_explain($s,'$s')});

#diag "With a plain constraint:\n  $explain_with\n";
#diag "With a parent constraint:\n  $explain_parent\n";
#diag "Without a plain constraint:\n  $explain_without\n";

$explain_with =~ s/(HasParam)_\w+/$1/g;
$explain_parent =~ s/(HasParam)_\w+/$1/g;
$explain_without =~ s/(HasParam)_\w+/$1/g;

ok $explain_with eq $explain_without;
ok $explain_parent eq $explain_without;

done_testing;
