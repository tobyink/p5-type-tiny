package Types::TypeTiny;

use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.023_01';

use Scalar::Util qw< blessed >;

our @EXPORT_OK = ( __PACKAGE__->type_names, qw/to_TypeTiny/ );

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

sub meta
{
	return $_[0];
}

sub get_type
{
	my $self = shift;
	my $func = $self->can(@_) or return;
	my $type = $func->();
	return $type if blessed($type) && $type->isa("Type::Tiny");
	return;
}

sub type_names
{
	 qw( CodeLike StringLike TypeTiny HashLike ArrayLike );
}

sub StringLike ()
{
	require Type::Tiny;
	$cache{StringLike} ||= "Type::Tiny"->new(
		name       => "StringLike",
		constraint => sub {    !ref($_   ) or Scalar::Util::blessed($_   ) && overload::Method($_   , q[""])  },
		inlined    => sub { qq/!ref($_[1]) or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[""])/ },
		library    => __PACKAGE__,
	);
}

sub HashLike ()
{
	require Type::Tiny;
	$cache{HashLike} ||= "Type::Tiny"->new(
		name       => "HashLike",
		constraint => sub {    ref($_   ) eq q[HASH] or Scalar::Util::blessed($_   ) && overload::Method($_   , q[%{}])  },
		inlined    => sub { qq/ref($_[1]) eq q[HASH] or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[\%{}])/ },
		library    => __PACKAGE__,
	);
}

sub ArrayLike ()
{
	require Type::Tiny;
	$cache{ArrayLike} ||= "Type::Tiny"->new(
		name       => "ArrayLike",
		constraint => sub {    ref($_   ) eq q[ARRAY] or Scalar::Util::blessed($_   ) && overload::Method($_   , q[@{}])  },
		inlined    => sub { qq/ref($_[1]) eq q[ARRAY] or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[\@{}])/ },
		library    => __PACKAGE__,
	);
}

sub CodeLike ()
{
	require Type::Tiny;
	$cache{CodeLike} ||= "Type::Tiny"->new(
		name       => "CodeLike",
		constraint => sub {    ref($_   ) eq q[CODE] or Scalar::Util::blessed($_   ) && overload::Method($_   , q[&{}])  },
		inlined    => sub { qq/ref($_[1]) eq q[CODE] or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[\&{}])/ },
		library    => __PACKAGE__,
	);
}

sub TypeTiny ()
{
	require Type::Tiny;
	$cache{TypeTiny} ||= "Type::Tiny"->new(
		name       => "TypeTiny",
		constraint => sub {  Scalar::Util::blessed($_   ) && $_   ->isa(q[Type::Tiny])  },
		inlined    => sub { my $var = $_[1]; "Scalar::Util::blessed($var) && $var\->isa(q[Type::Tiny])" },
		library    => __PACKAGE__,
	);
}

sub to_TypeTiny
{
	my $t = $_[0];
	
	return $t unless ref $t;
	return $t if ref($t) =~ /^Type::Tiny\b/;
	
	if (my $class = blessed $t)
	{
		return $t                           if $class->isa("Type::Tiny");
		goto \&_TypeTinyFromMoose           if $class->isa("Moose::Meta::TypeConstraint");
		goto \&_TypeTinyFromMoose           if $class->isa("MooseX::Types::TypeDecorator");
		goto \&_TypeTinyFromValidationClass if $class->isa("Validation::Class::Simple");
		goto \&_TypeTinyFromValidationClass if $class->isa("Validation::Class");
		goto \&_TypeTinyFromGeneric         if $t->can("check") && $t->can("get_message"); # i.e. Type::API::Constraint
	}
	
	goto \&_TypeTinyFromCodeRef if ref($t) eq q(CODE);
	
	$t;
}

sub _TypeTinyFromMoose
{
	my $t = $_[0];
	
	if (ref $t->{"Types::TypeTiny::to_TypeTiny"})
	{
		return $t->{"Types::TypeTiny::to_TypeTiny"};
	}
	
	if ($t->name ne '__ANON__') {
		require Types::Standard;
		my $ts = 'Types::Standard'->get_type($t->name);
		return $ts if $ts->{_is_core};
	}
	
	my %opts;
	$opts{display_name} = $t->name;
	$opts{constraint}   = $t->constraint;
	$opts{parent}       = to_TypeTiny($t->parent)              if $t->has_parent;
	$opts{inlined}      = sub { shift; $t->_inline_check(@_) } if $t->can_be_inlined;
	$opts{message}      = sub { $t->get_message($_) }          if $t->has_message;
	$opts{moose_type}   = $t;
	
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

sub _TypeTinyFromGeneric
{
	my $t = $_[0];
	
	# XXX - handle inlining??
	# XXX - handle display_name????
	
	my %opts = (
		constraint => sub { $t->check(@_ ? @_ : $_) },
		message    => sub { $t->get_message(@_ ? @_ : $_) },
	);
	
	$opts{display_name} = $t->name if $t->can("name");
	
	$opts{coercion} = sub { $t->coerce(@_ ? @_ : $_) }
		if $t->can("has_coercion") && $t->has_coercion && $t->can("coerce");
	
	require Type::Tiny;
	return "Type::Tiny"->new(%opts);
}

sub _TypeTinyFromCodeRef
{
	my $t = $_[0];
	
	require Type::Tiny;
	return "Type::Tiny"->new(
		constraint => sub {
			return !!eval { $t->($_) };
		},
		message => sub {
			local $@;
			eval { $t->($_); 1 } or do { chomp $@; return $@ if $@ };
			return sprintf('%s did not pass type constraint', Type::Tiny::_dd($_));
		},
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

=item C<< ArrayLike >>

=item C<< CodeLike >>

=item C<< TypeTiny >>

=back

=head2 Coercion Functions

=over

=item C<< to_TypeTiny($constraint) >>

Promotes (or "demotes" if you prefer) a Moose::Meta::TypeConstraint object
to a Type::Tiny object.

Can also handle L<Validation::Class> objects. Type constraints built from 
Validation::Class objects deliberately I<ignore> field filters when they
do constraint checking (and go to great lengths to do so); using filters for
coercion only. (The behaviour of C<coerce> if we don't do that is just too
weird!)

Can also handle any object providing C<check> and C<get_message> methods.
(This includes L<Mouse::Meta::TypeConstraint> objects.) If the object also
provides C<has_coercion> and C<coerce> methods, these will be used too.

Can also handle coderefs (but not blessed coderefs or objects overloading
C<< &{} >>). Coderefs are expected to return true iff C<< $_ >> passes the
constraint. If C<< $_ >> fails the type constraint, they may either return
false, or die with a helpful error message.

=back

=head2 Methods

These are implemented so that C<< Types::TypeTiny->meta->get_type($foo) >>
works, for rough compatibility with a real L<Type::Library> type library.

=over

=item C<< meta >>

=item C<< get_type($name) >>

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

