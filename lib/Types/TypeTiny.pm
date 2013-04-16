package Types::TypeTiny;

use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003_02';

use Scalar::Util qw< blessed >;

use base "Exporter";
our @EXPORT_OK = qw( CodeLike StringLike TypeTiny HashLike to_TypeTiny );

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

sub to_TypeTiny
{
	my $t = $_[0];
	
	if (blessed($t) and ref($t)->isa("Moose::Meta::TypeConstraint"))
	{
		if ($t->can("tt_type") and my $tt = $t->tt_type)
		{
			return $tt;
		}
		
		my %opts;
		$opts{name}       = $t->name;
		$opts{constraint} = $t->constraint;
		$opts{parent}     = to_TypeTiny($t->parent)              if $t->has_parent;
		$opts{inlined}    = sub { shift; $t->_inline_check(@_) } if $t->can_be_inlined;
		$opts{message}    = sub { $t->get_message($_) }          if $t->has_message;
		
		require Type::Tiny;
		return "Type::Tiny"->new(%opts);
	}
	
	return $t;
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

=item C<< TypeTiny >>, C<< to_TypeTiny >>

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

