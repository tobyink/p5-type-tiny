package Types::Common::String;

use 5.006001;
use strict;
use warnings;
use utf8;

BEGIN {
	if ($] < 5.008) { require Devel::TypeTiny::Perl56Compat };
}

BEGIN {
	$Types::Common::String::AUTHORITY = 'cpan:TOBYINK';
	$Types::Common::String::VERSION   = '1.002001';
}

use Type::Library -base, -declare => qw(
	SimpleStr
	NonEmptySimpleStr
	NumericCode
	LowerCaseSimpleStr
	UpperCaseSimpleStr
	Password
	StrongPassword
	NonEmptyStr
	LowerCaseStr
	UpperCaseStr
);

use Type::Tiny ();
use Types::Standard qw( Str );

my $meta = __PACKAGE__->meta;

$meta->add_type(
	name       => SimpleStr,
	parent     => Str,
	constraint => sub { length($_) <= 255 and not /\n/ },
	inlined    => sub { undef, qq(length($_) <= 255), qq($_ !~ /\\n/) },
	message    => sub { "Must be a single line of no more than 255 chars" },
);

$meta->add_type(
	name       => NonEmptySimpleStr,
	parent     => SimpleStr,
	constraint => sub { length($_) > 0 },
	inlined    => sub { undef, qq(length($_) > 0) },
	message    => sub { "Must be a non-empty single line of no more than 255 chars" },
);

$meta->add_type(
	name       => NumericCode,
	parent     => NonEmptySimpleStr,
	constraint => sub { /^[0-9]+$/ },
	inlined    => sub { SimpleStr->inline_check($_), qq($_ =~ m/^[0-9]+\$/) },
	message    => sub {
		'Must be a non-empty single line of no more than 255 chars that consists '
			. 'of numeric characters only'
	},
);

NumericCode->coercion->add_type_coercions(
	NonEmptySimpleStr, q[ do { (my $code = $_) =~ s/[[:punct:][:space:]]//g; $code } ],
);

$meta->add_type(
	name       => Password,
	parent     => NonEmptySimpleStr,
	constraint => sub { length($_) > 3 },
	inlined    => sub { SimpleStr->inline_check($_), qq(length($_) > 3) },
	message    => sub { "Must be between 4 and 255 chars" },
);

$meta->add_type(
	name       => StrongPassword,
	parent     => Password,
	constraint => sub { length($_) > 7 and /[^a-zA-Z]/ },
	inlined    => sub { SimpleStr()->inline_check($_), qq(length($_) > 7), qq($_ =~ /[^a-zA-Z]/) },
	message    => sub { "Must be between 8 and 255 chars, and contain a non-alpha char" },
);

my ($nestr);
if (Type::Tiny::_USE_XS) {
	$nestr = Type::Tiny::XS::get_coderef_for('NonEmptyStr');
}

$meta->add_type(
	name       => NonEmptyStr,
	parent     => Str,
	constraint => sub { length($_) > 0 },
	inlined    => sub {
		if ($nestr) {
			my $xsub = Type::Tiny::XS::get_subname_for($_[0]->name);
			return "$xsub($_[1])" if $xsub;
		}
		undef, qq(length($_) > 0);
	},
	message    => sub { "Must not be empty" },
	$nestr ? ( compiled_type_constraint => $nestr ) : (),
);

$meta->add_type(
	name       => LowerCaseStr,
	parent     => NonEmptyStr,
	constraint => sub { !/\p{Upper}/ms },
	inlined    => sub { undef, qq($_ !~ /\\p{Upper}/ms) },
	message    => sub { "Must not contain upper case letters" },
);

LowerCaseStr->coercion->add_type_coercions(
	NonEmptyStr, q[ lc($_) ],
);

$meta->add_type(
	name       => UpperCaseStr,
	parent     => NonEmptyStr,
	constraint => sub { !/\p{Lower}/ms },
	inlined    => sub { undef, qq($_ !~ /\\p{Lower}/ms) },
	message    => sub { "Must not contain lower case letters" },
);

UpperCaseStr->coercion->add_type_coercions(
	NonEmptyStr, q[ uc($_) ],
);

$meta->add_type(
	name       => LowerCaseSimpleStr,
	parent     => NonEmptySimpleStr,
	constraint => sub { !/\p{Upper}/ms },
	inlined    => sub { undef, qq($_ !~ /\\p{Upper}/ms) },
	message    => sub { "Must not contain pper case letters" },
);

LowerCaseSimpleStr->coercion->add_type_coercions(
	NonEmptySimpleStr, q[ lc($_) ],
);

$meta->add_type(
	name       => UpperCaseSimpleStr,
	parent     => NonEmptySimpleStr,
	constraint => sub { !/\p{Lower}/ms },
	inlined    => sub { undef, qq($_ !~ /\\p{Lower}/ms) },
	message    => sub { "Must not contain lower case letters" },
);

UpperCaseSimpleStr->coercion->add_type_coercions(
	NonEmptySimpleStr, q[ uc($_) ],
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Common::String - drop-in replacement for MooseX::Types::Common::String

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

A drop-in replacement for L<MooseX::Types::Common::String>.

=head2 Types

The following types are similar to those described in
L<MooseX::Types::Common::String>.

=over

=item C<SimpleStr>

=item C<NonEmptySimpleStr>

=item C<NumericCode>

=item C<LowerCaseSimpleStr>

=item C<UpperCaseSimpleStr>

=item C<Password>

=item C<StrongPassword>

=item C<NonEmptyStr>

=item C<LowerCaseStr>

=item C<UpperCaseStr>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Types::Standard>, L<Types::Common::Numeric>.

L<MooseX::Types::Common>,
L<MooseX::Types::Common::Numeric>,
L<MooseX::Types::Common::String>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

