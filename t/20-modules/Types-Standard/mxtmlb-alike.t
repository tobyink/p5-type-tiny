=pod

=encoding utf-8

=head1 PURPOSE

Test the following types from L<Types::Standard> which were inspired by
L<MooX::Types::MooseLike::Base>.

=over

=item C<< InstanceOf >>

=item C<< ConsumerOf >>

=item C<< HasMethods >>

=item C<< Enum >>

=back

Rather than checking they work directy, we check they are equivalent to
known (and well-tested) type constraints generated using L<Type::Utils>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;

use Types::Standard -types;
use Type::Utils;

sub same_type
{
	my ($a, $b, $msg) = @_;
	$msg ||= "$a == $b";
	
	@_ = ($a->inline_check('$x'), $b->inline_check('$x'), $msg);
	goto \&Test::More::is;
}

same_type(
	InstanceOf[],
	Object,
);

same_type(
	InstanceOf["Foo"],
	class_type(Foo => {class => "Foo"}),
);

same_type(
	InstanceOf["Foo", "Bar"],
	union [
		class_type(Foo => {class => "Foo"}),
		class_type(Bar => {class => "Bar"}),
	],
);

same_type(
	ConsumerOf[],
	Object,
);

same_type(
	ConsumerOf["Foo"],
	role_type(Foo => {role => "Foo"}),
);

same_type(
	ConsumerOf["Foo", "Bar"],
	intersection [
		role_type(Foo => {role => "Foo"}),
		role_type(Bar => {role => "Bar"}),
	],
);

same_type(
	HasMethods[],
	Object,
);

same_type(
	HasMethods["foo"],
	duck_type(CanFoo => [qw/foo/]),
);

same_type(
	HasMethods["foo", "bar"],
	duck_type(CanFooBar => [qw/foo bar/]),
);

same_type(
	Enum[],
	Str,
);

same_type(
	Enum["foo"],
	enum(Foo => [qw/foo/]),
);

same_type(
	Enum["foo", "bar"],
	enum(Foo => [qw/foo bar/]),
);

done_testing;
