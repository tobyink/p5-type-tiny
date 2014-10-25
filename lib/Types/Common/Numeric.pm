package Types::Common::Numeric;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ($] < 5.008) { require Devel::TypeTiny::Perl56Compat };
}

BEGIN {
	$Types::Common::Numeric::AUTHORITY = 'cpan:TOBYINK';
	$Types::Common::Numeric::VERSION   = '1.000005';
}

use Type::Library -base, -declare => qw(
	PositiveNum PositiveOrZeroNum
	PositiveInt PositiveOrZeroInt
	NegativeNum NegativeOrZeroNum
	NegativeInt NegativeOrZeroInt
	SingleDigit
);

use Type::Tiny ();
use Types::Standard qw( Num Int );

my $meta = __PACKAGE__->meta;

$meta->add_type(
	name       => 'PositiveNum',
	parent     => Num,
	constraint => sub { $_ > 0 },
	inlined    => sub { undef, qq($_ > 0) },
	message    => sub { "Must be a positive number" },
);

$meta->add_type(
	name       => 'PositiveOrZeroNum',
	parent     => Num,
	constraint => sub { $_ >= 0 },
	inlined    => sub { undef, qq($_ >= 0) },
	message    => sub { "Must be a number greater than or equal to zero" },
);

my ($pos_int, $posz_int);
if (Type::Tiny::_USE_XS) {
	$pos_int  = Type::Tiny::XS::get_coderef_for('PositiveInt');
	$posz_int = Type::Tiny::XS::get_coderef_for('PositiveOrZeroInt');
}

$meta->add_type(
	name       => 'PositiveInt',
	parent     => Int,
	constraint => sub { $_ > 0 },
	inlined    => sub {
		if ($pos_int) {
			my $xsub = Type::Tiny::XS::get_subname_for($_[0]->name);
			return "$xsub($_[1])" if $xsub;
		}
		undef, qq($_ > 0);
	},
	message    => sub { "Must be a positive integer" },
	$pos_int ? ( compiled_type_constraint => $pos_int ) : (),
);

$meta->add_type(
	name       => 'PositiveOrZeroInt',
	parent     => Int,
	constraint => sub { $_ >= 0 },
	inlined    => sub {
		if ($posz_int) {
			my $xsub = Type::Tiny::XS::get_subname_for($_[0]->name);
			return "$xsub($_[1])" if $xsub;
		}
		undef, qq($_ >= 0);
	},
	message    => sub { "Must be an integer greater than or equal to zero" },
	$posz_int ? ( compiled_type_constraint => $posz_int ) : (),
);

$meta->add_type(
	name       => 'NegativeNum',
	parent     => Num,
	constraint => sub { $_ < 0 },
	inlined    => sub { undef, qq($_ < 0) },
	message    => sub { "Must be a negative number" },
);

$meta->add_type(
	name       => 'NegativeOrZeroNum',
	parent     => Num,
	constraint => sub { $_ <= 0 },
	inlined    => sub { undef, qq($_ <= 0) },
	message    => sub { "Must be a number less than or equal to zero" },
);

$meta->add_type(
	name       => 'NegativeInt',
	parent     => Int,
	constraint => sub { $_ < 0 },
	inlined    => sub { undef, qq($_ < 0) },
	message    => sub { "Must be a negative integer" },
);

$meta->add_type(
	name       => 'NegativeOrZeroInt',
	parent     => Int,
	constraint => sub { $_ <= 0 },
	inlined    => sub { undef, qq($_ <= 0) },
	message    => sub { "Must be an integer less than or equal to zero" },
);

$meta->add_type(
	name       => 'SingleDigit',
	parent     => Int,
	constraint => sub { $_ >= -9 and $_ <= 9 },
	inlined    => sub { undef, qq($_ >= -9), qq($_ <= 9) },
	message    => sub { "Must be a single digit" },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Common::Numeric - drop-in replacement for MooseX::Types::Common::Numeric

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

A drop-in replacement for L<MooseX::Types::Common::Numeric>.

=head2 Types

The following types are similar to those described in
L<MooseX::Types::Common::Numeric>.

=over

=item C<PositiveNum>

=item C<PositiveOrZeroNum>

=item C<PositiveInt>

=item C<PositiveOrZeroInt>

=item C<NegativeNum>

=item C<NegativeOrZeroNum>

=item C<NegativeInt>

=item C<NegativeOrZeroInt>

=item C<SingleDigit>

=back

C<SingleDigit> interestingly accepts the numbers -9 to -1; not
just 0 to 9. 

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Types::Standard>, L<Types::Common::String>.

L<MooseX::Types::Common>,
L<MooseX::Types::Common::Numeric>,
L<MooseX::Types::Common::String>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

