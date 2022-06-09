=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Error::TypeTiny> interaction with L<Moo>.

=head1 DEPENDENCIES

Requires Moo 1.002001 or above; skipped otherwise.

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
use Test::Fatal;
use Test::Requires { "Moo" => "1.004000" };

BEGIN {
	require Method::Generate::Accessor;
	"Method::Generate::Accessor"->can("_SIGDIE")
		or "Moo"->VERSION ge '1.006'
		or plan skip_all => "Method::Generate::Accessor exception support seems missing!!!";
};

{
	package Goo;
	use Moo;
	use Types::Standard qw(Int);
	has number => (is => "rw", isa => Int);
}

my $e_constructor = exception { Goo->new(number => "too") };

isa_ok($e_constructor, 'Error::TypeTiny::Assertion', '$e_constructor');
ok($e_constructor->has_attribute_name, '$e_constructor->has_attribute_name');
is($e_constructor->attribute_name, 'number', '$e_constructor->attribute_name');
ok($e_constructor->has_attribute_step, '$e_constructor->has_attribute_step');
is($e_constructor->attribute_step, 'isa check', '$e_constructor->attribute_step');
is($e_constructor->varname, '$args->{"number"}', '$e_constructor->varname');
is($e_constructor->value, "too", '$e_constructor->value');
is($e_constructor->type, Types::Standard::Int, '$e_constructor->type');

my $e_accessor    = exception { Goo->new->number("too") };

isa_ok($e_accessor, 'Error::TypeTiny::Assertion', '$e_accessor');
ok($e_accessor->has_attribute_name, '$e_accessor->has_attribute_name');
is($e_accessor->attribute_name, 'number', '$e_accessor->attribute_name');
ok($e_accessor->has_attribute_step, '$e_accessor->has_attribute_step');
is($e_accessor->attribute_step, 'isa check', '$e_accessor->attribute_step');
is($e_accessor->value, "too", '$e_accessor->value');
is($e_accessor->type, Types::Standard::Int, '$e_accessor->type');

done_testing;
