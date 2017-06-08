package Types::TypeTiny;

use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.002001';

use Scalar::Util qw< blessed refaddr weaken >;

our @EXPORT_OK = ( __PACKAGE__->type_names, qw/to_TypeTiny/ );

my %cache;

sub import
{
	# do the shuffle!
	no warnings "redefine";
	our @ISA = qw( Exporter::Tiny );
	require Exporter::Tiny;
	my $next = \&Exporter::Tiny::import;
	*import = $next;
	my $class = shift;
	my $opts  = { ref($_[0]) ? %{+shift} : () };
	$opts->{into} ||= scalar(caller);
	return $class->$next($opts, @_);
}

sub meta
{
	return $_[0];
}

sub type_names
{
	qw( CodeLike StringLike TypeTiny HashLike ArrayLike );
}

sub has_type
{
	my %has = map +($_ => 1), shift->type_names;
	!!$has{ $_[0] };
}

sub get_type
{
	my $self = shift;
	return unless $self->has_type(@_);
	no strict qw(refs);
	&{$_[0]}();
}

sub coercion_names
{
	qw();
}

sub has_coercion
{
	my %has = map +($_ => 1), shift->coercion_names;
	!!$has{ $_[0] };
}

sub get_coercion
{
	my $self = shift;
	return unless $self->has_coercion(@_);
	no strict qw(refs);
	&{$_[0]}();  # uncoverable statement
}

sub StringLike ()
{
	require Type::Tiny;
	$cache{StringLike} ||= "Type::Tiny"->new(
		name       => "StringLike",
		constraint => sub {    defined($_   ) && !ref($_   ) or Scalar::Util::blessed($_   ) && overload::Method($_   , q[""])  },
		inlined    => sub { qq/defined($_[1]) && !ref($_[1]) or Scalar::Util::blessed($_[1]) && overload::Method($_[1], q[""])/ },
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

my %ttt_cache;

sub to_TypeTiny
{
	my $t = $_[0];
	
	return $t unless (my $ref = ref $t);
	return $t if $ref =~ /^Type::Tiny\b/;
	
	return $ttt_cache{ refaddr($t) } if $ttt_cache{ refaddr($t) };
	
	if (my $class = blessed $t)
	{
		return $t                               if $class->isa("Type::Tiny");
		return _TypeTinyFromMoose($t)           if $class->isa("Moose::Meta::TypeConstraint");
		return _TypeTinyFromMoose($t)           if $class->isa("MooseX::Types::TypeDecorator");
		return _TypeTinyFromValidationClass($t) if $class->isa("Validation::Class::Simple");
		return _TypeTinyFromValidationClass($t) if $class->isa("Validation::Class");
		return _TypeTinyFromGeneric($t)         if $t->can("check") && $t->can("get_message"); # i.e. Type::API::Constraint
	}
	
	return _TypeTinyFromCodeRef($t) if $ref eq q(CODE);
	
	$t;
}

sub _TypeTinyFromMoose
{
	my $t = $_[0];
	
	if (ref $t->{"Types::TypeTiny::to_TypeTiny"})
	{
		return $t->{"Types::TypeTiny::to_TypeTiny"};
	}
	
	if ($t->name ne '__ANON__')
	{
		require Types::Standard;
		my $ts = 'Types::Standard'->get_type($t->name);
		return $ts if $ts->{_is_core};
	}
	
	my %opts;
	$opts{display_name} = $t->name;
	$opts{constraint}   = $t->constraint;
	$opts{parent}       = to_TypeTiny($t->parent)              if $t->has_parent;
	$opts{inlined}      = sub { shift; $t->_inline_check(@_) } if $t->can("can_be_inlined") && $t->can_be_inlined;
	$opts{message}      = sub { $t->get_message($_) }          if $t->has_message;
	$opts{moose_type}   = $t;
	
	require Type::Tiny;
	my $new = 'Type::Tiny'->new(%opts);
	$ttt_cache{ refaddr($t) } = $new;
	weaken($ttt_cache{ refaddr($t) });
	
	$new->{coercion} = do {
		require Type::Coercion::FromMoose;
		'Type::Coercion::FromMoose'->new(
			type_constraint => $new,
			moose_coercion  => $t->coercion,
		);
	} if $t->has_coercion;
	
	return $new;
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
	
	require Type::Tiny;
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
	
	$ttt_cache{ refaddr($t) } = $new;
	weaken($ttt_cache{ refaddr($t) });
	return $new;
}

sub _TypeTinyFromGeneric
{
	my $t = $_[0];
	
	# XXX - handle inlining??
	
	my %opts = (
		constraint => sub { $t->check(@_ ? @_ : $_) },
		message    => sub { $t->get_message(@_ ? @_ : $_) },
	);
	
	$opts{display_name} = $t->name if $t->can("name");
	
	$opts{coercion} = sub { $t->coerce(@_ ? @_ : $_) }
		if $t->can("has_coercion") && $t->has_coercion && $t->can("coerce");
	
	require Type::Tiny;
	my $new = "Type::Tiny"->new(%opts);
	$ttt_cache{ refaddr($t) } = $new;
	weaken($ttt_cache{ refaddr($t) });
	return $new;
}

my $QFS;
sub _TypeTinyFromCodeRef
{
	my $t = $_[0];
	
	my %opts = (
		constraint => sub {
			return !!eval { $t->($_) };
		},
		message => sub {
			local $@;
			eval { $t->($_); 1 } or do { chomp $@; return $@ if $@ };
			return sprintf('%s did not pass type constraint', Type::Tiny::_dd($_));
		},
	);
	
	if ($QFS ||= "Sub::Quote"->can("quoted_from_sub"))
	{
		my (undef, $perlstring, $captures) = @{ $QFS->($t) || [] };
		if ($perlstring)
		{
			$perlstring = "!!eval{ $perlstring }";
			$opts{inlined} = sub
			{
				my $var = $_[1];
				Sub::Quote::inlinify(
					$perlstring,
					$var,
					$var eq q($_) ? '' : "local \$_ = $var;",
					1,
				);
			} if $perlstring && !$captures;
		}
	}
	
	require Type::Tiny;
	my $new = "Type::Tiny"->new(%opts);
	$ttt_cache{ refaddr($t) } = $new;
	weaken($ttt_cache{ refaddr($t) });
	return $new;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords arrayfication hashification

=head1 NAME

Types::TypeTiny - type constraints used internally by Type::Tiny

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

Dogfooding.

This isn't a real Type::Library-based type library; that would involve
too much circularity. But it exports some type constraints which, while
designed for use within Type::Tiny, may be more generally useful.

=head2 Types

=over

=item C<< StringLike >>

Accepts strings and objects overloading stringification.

=item C<< HashLike >>

Accepts hashrefs and objects overloading hashification.

=item C<< ArrayLike >>

Accepts arrayrefs and objects overloading arrayfication.

=item C<< CodeLike >>

Accepts coderefs and objects overloading codification.

=item C<< TypeTiny >>

Accepts blessed L<Type::Tiny> objects.

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

=item C<< type_names >>

=item C<< get_type($name) >>

=item C<< has_type($name) >>

=item C<< coercion_names >>

=item C<< get_coercion($name) >>

=item C<< has_coercion($name) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>.

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

