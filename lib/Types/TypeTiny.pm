package Types::TypeTiny;

use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Scalar::Util qw< blessed >;

our @EXPORT_OK = qw( CodeLike StringLike TypeTiny HashLike to_TypeTiny );

my %cache;

sub import
{
	# do the shuffle!
	no warnings "redefine";
	our @ISA = qw( Exporter::TypeTiny );
	require Exporter::TypeTiny;
	my $next = \&Exporter::TypeTiny::import;
	*import = $next;
	goto $next;
}

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
	
	goto \&_TypeTinyFromMoose
		if (blessed($t) and ref($t)->isa("Moose::Meta::TypeConstraint"));
	
	goto \&_TypeTinyFromMouse
		if (blessed($t) and ref($t)->isa("Mouse::Meta::TypeConstraint"));
	
	goto \&_TypeTinyFromValidationClass
		if (blessed($t) and ref($t)->isa("Validation::Class::Simple") || ref($t)->isa("Validation::Class"));
	
	$t;
}

sub _TypeTinyFromMoose
{
	my $t = $_[0];
	
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
	$opts{moose_type} = $t;
	
	require Type::Tiny;
	return "Type::Tiny"->new(%opts);
}

sub _TypeTinyFromMouse
{
	my $t = $_[0];
	
	my %opts;
	$opts{name}       = $t->name;
	$opts{constraint} = $t->constraint;
	$opts{parent}     = to_TypeTiny($t->parent)              if $t->has_parent;
	$opts{message}    = sub { $t->get_message($_) }          if $t->has_message;
	$opts{mouse_type} = $t;
	
	require Type::Tiny;
	return "Type::Tiny"->new(%opts);
}

sub _TypeTinyFromValidationClass
{
	my $t = $_[0];
	
	require Type::Tiny;
	require Types::Standard;
	
	my %opts = (
		parent            => Types::Standard::HashRef(),
		_validation_class => $t,
	);
	
	if ($t->VERSION >= "7.900048")
	{
		$opts{constraint} = sub {
			$t->params->clear;
			$t->params->add(%$_);
			my $f = $t->filtering; $t->filtering('off');
			my $r = eval { $t->validate };
			$t->filtering($f || 'pre');
			return $r;
		};
		$opts{message} = sub {
			$t->params->clear;
			$t->params->add(%$_);
			my $f = $t->filtering; $t->filtering('off');
			my $r = (eval { $t->validate } ? "OK" : $t->errors_to_string);
			$t->filtering($f || 'pre');
			return $r;
		};
	}
	else  # need to use hackish method
	{
		$opts{constraint} = sub {
			$t->params->clear;
			$t->params->add(%$_);
			no warnings "redefine";
			local *Validation::Class::Directive::Filters::execute_filtering = sub { $_[0] };
			eval { $t->validate };
		};
		$opts{message} = sub {
			$t->params->clear;
			$t->params->add(%$_);
			no warnings "redefine";
			local *Validation::Class::Directive::Filters::execute_filtering = sub { $_[0] };
			eval { $t->validate } ? "OK" : $t->errors_to_string;
		};
	}
	
	my $new = "Type::Tiny"->new(%opts);
	
	$new->coercion->add_type_coercions(
		Types::Standard::HashRef() => sub {
			my %params = %$_;
			for my $k (keys %params)
				{ delete $params{$_} unless $t->get_fields($k) };
			$t->params->clear;
			$t->params->add(%params);
			eval { $t->validate };
			$t->get_hash;
		},
	);
	
	return $new;
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

=head2 Coercion Functions

=over

=item C<< to_TypeTiny($constraint) >>

Promotes (or "demotes" if you prefer) a Moose/Mouse::Meta::TypeConstraint object
to a Type::Tiny object.

Can also handle L<Validation::Class> objects. Type constraints built from 
Validation::Class objects deliberately I<ignore> field filters when they
do constraint checking (and go to great lengths to do so); using filters for
coercion only. (The behaviour of C<coerce> if we don't do that is just too
weird!)

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

