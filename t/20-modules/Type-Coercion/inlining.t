=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion can be inlined.

=head1 DEPENDENCIES

Requires JSON::PP 2.27105. Test is skipped if this module is not present.
Note that this is bundled with Perl v5.13.11 and above.

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

use Test::Requires { "JSON::PP" => "2.27105" };

use Test::More;
use Test::Fatal;

{
	package T;
	
	require JSON::PP;
	
	use Type::Library -base, -declare => qw/ JsonHash JsonArray /;
	use Type::Utils;
	use Types::Standard -types;
	
	declare JsonHash, as HashRef;
	declare JsonArray, as ArrayRef;
	
	coerce JsonHash,
		from Str, 'JSON::PP::decode_json($_)';
	
	coerce JsonArray,
		from Str, 'JSON::PP::decode_json($_)';
	
	__PACKAGE__->meta->make_immutable;
}

my $code = T::JsonArray->coercion->inline_coercion('$::foo');

our $foo = "[3,2,1]";

is_deeply(
	eval $code,
	[3,2,1],
	'inlined coercion works',
);

$foo = [5,4,3];

is_deeply(
	eval $code,
	[5,4,3],
	'no coercion necessary',
);

$foo = {foo => "bar"};

is_deeply(
	eval $code,
	{foo => "bar"},
	'no coercion possible',
);

done_testing;
