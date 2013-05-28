=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Exporter::TypeTiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

require Types::Standard;

is(
	exception { "Types::Standard"->import("Any") },
	undef,
	q {No exception exporting a legitimate function},
);

can_ok(main => "Any");

like(
	exception { "Types::Standard"->import("kghffubbtfui") },
	qr{^Could not find sub 'kghffubbtfui' to export in package 'Types::Standard'},
	q {Attempt to export a function which does not exist},
);

like(
	exception { "Types::Standard"->import("declare") },
	qr{^Could not find sub 'declare' to export in package 'Types::Standard'},
	q {Attempt to export a function which exists but not in @EXPORT_OK},
);

{
	my $hash = {};
	"Types::Standard"->import({ into => $hash }, qw(-types));
	is_deeply(
		[ sort keys %$hash ],
		[ sort "Types::Standard"->meta->type_names ],
		'"-types" shortcut works',
	);
};

{
	my $hash = {};
	"Types::Standard"->import({ into => $hash }, qw(-coercions));
	is_deeply(
		[ sort keys %$hash ],
		[ sort "Types::Standard"->meta->coercion_names ],
		'"-coercions" shortcut works',
	);
};

{
	my $hash = {};
	"Types::Standard"->import({ into => $hash }, Str    => {                 });
	"Types::Standard"->import({ into => $hash }, Str    => { -as => "String" });
	"Types::Standard"->import({ into => $hash }, -types => { -prefix => "X_" });
	"Types::Standard"->import({ into => $hash }, -types => { -suffix => "_Z" });
	is($hash->{Str}, $hash->{String}, 'renaming works');
	is($hash->{Str}, $hash->{X_Str}, 'prefixes work');
	is($hash->{Str}, $hash->{Str_Z}, 'suffixes work');
};

{
	my $hash = {};
	"Types::Standard"->import({ into => $hash }, qw(+Str));
	is_deeply(
		[sort keys %$hash],
		[sort qw/ assert_Str to_Str is_Str Str /],
		'plus notation works for Type::Library',
	);
};

my $opthash = Exporter::TypeTiny::mkopt_hash([ foo => [], "bar" ]);

is_deeply(
	$opthash,
	{ foo => [], bar => undef },
	'mkopt_hash',
) or diag explain($opthash);

done_testing;
