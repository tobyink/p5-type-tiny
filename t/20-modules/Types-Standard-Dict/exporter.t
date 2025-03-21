=pod

=encoding utf-8

=head1 PURPOSE

Checks Types::Standard::Dict can export.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Types::Standard -types;

use Types::Standard::Dict (
	Credentials => { of => [
		username => Str,
		password => Str,
	] },
	Headers => { of => [
		'Content-Type' => Optional[Str],
		'Accept'       => Optional[Str],
		'User-Agent'   => Optional[Str],
	] },
);

use Types::Standard::Dict (
	HttpRequestData => { of => [
		credentials => Credentials,
		headers     => Headers,
		url         => Str,
		method      => Enum[ qw( OPTIONS HEAD GET POST PUT DELETE PATCH ) ],
	] },
);

ok is_HttpRequestData( {
	credentials => { username => 'bob', password => 's3cr3t' },
	headers     => { 'Accept' => 'application/json' },
	url         => 'http://example.net/api/v1/stuff',
	method      => 'GET',
} );

done_testing;
