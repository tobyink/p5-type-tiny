=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Registry refcount stuff.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires 'Devel::Refcount';
use Devel::Refcount 'refcount';
use Types::Standard qw( Int );
use Type::Registry;

my $orig_count = refcount( Int );
note "COUNT: $orig_count";

{
	my $reg = Type::Registry->new;
	$reg->add_types(qw/ -Standard /);
	
	is refcount( Int ), 1 + $orig_count;
}

is refcount( Int ), $orig_count;

done_testing;
