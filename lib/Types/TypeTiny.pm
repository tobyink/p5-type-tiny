package Types::TypeTiny;

use base "Exporter";

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_07';

our @EXPORT_OK = qw( CodeLike StringLike TypeTiny HashLike );

my %cache;

sub StringLike ()
{
	require Type::Tiny;
	$cache{StringLike} ||= "Type::Tiny"->new(
		name       => "StringLike",
		constraint => sub {    !ref($_   ) or Scalar::Util::blessed($_   ) && overload::Method($_   , q[""])  },
		inlined    => sub { qq/!ref($_[1]) or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[""])/ },
	);
}

sub HashLike ()
{
	require Type::Tiny;
	$cache{HashLike} ||= "Type::Tiny"->new(
		name       => "HashLike",
		constraint => sub {    ref($_   ) eq q[HASH] or Scalar::Util::blessed($_   ) && overload::Method($_   , q[%{}])  },
		inlined    => sub { qq/ref($_[1]) eq q[HASH] or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[\%{}])/ },
	);
}

sub CodeLike ()
{
	require Type::Tiny;
	$cache{CodeLike} ||= "Type::Tiny"->new(
		name       => "CodeLike",
		constraint => sub {    ref($_   ) eq q[CODE] or Scalar::Util::blessed($_   ) && overload::Method($_   , q[&{}])  },
		inlined    => sub { qq/ref($_[1]) eq q[CODE] or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[\&{}])/ },
	);
}

sub TypeTiny ()
{
	require Type::Tiny;
	$cache{TypeTiny} ||= "Type::Tiny"->new(
		name       => "TypeTiny",
		constraint => sub {  Scalar::Util::blessed($_   ) && $_   ->isa(q[Type::Tiny])  },
		inlined    => sub { my $var = $_[1]; "Scalar::Util::blessed($var) && $var\->isa(q[Type::Tiny])" },
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::TypeTiny - type constraints used internally by Type::Tiny

=head1 DESCRIPTION

Dogfooding.

This isn't a real Type::Library-based type library; that would involve too
much circularity. But it exports some type constraint "constants":

=head2 Types

=over

=item C<< StringLike >>

=item C<< HashLike >>

=item C<< CodeLike >>

=item C<< TypeTiny >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

