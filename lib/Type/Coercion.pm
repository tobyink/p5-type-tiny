package Type::Coercion;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Coercion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Coercion::VERSION   = '0.003_07';
}

use Scalar::Util qw< blessed >;
use Types::TypeTiny ();

sub _croak ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
}

use overload
	q("")      => sub { caller =~ m{^(Moo::HandleMoose|Sub::Quote)} ? overload::StrVal($_[0]) : $_[0]->display_name },
	q(bool)    => sub { 1 },
	q(&{})     => "_overload_coderef",
	q(+)       => sub { __PACKAGE__->add(@_) },
	fallback   => 1,
;
BEGIN {
	overload->import(q(~~) => sub { $_[0]->has_coercion_for_value($_[1]) })
		if $] >= 5.010001;
}

sub _overload_coderef
{
	my $self = shift;
	$self->{_overload_coderef} ||= "Sub::Quote"->can("quote_sub") && $self->can_be_inlined
		? Sub::Quote::quote_sub($self->inline_coercion('$_[0]'))
		: sub { $self->coerce(@_) }
}

sub new
{
	my $class  = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	
	$params{name} = '__ANON__' unless exists $params{name};
	
	my $self   = bless \%params, $class;
	Scalar::Util::weaken($self->{type_constraint}); # break ref cycle
	return $self;
}

sub name                   { $_[0]{name} }
sub display_name           { $_[0]{display_name}      ||= $_[0]->_build_display_name }
sub library                { $_[0]{library} }
sub type_constraint        { $_[0]{type_constraint} }
sub type_coercion_map      { $_[0]{type_coercion_map} ||= [] }
sub moose_coercion         { $_[0]{moose_coercion}    ||= $_[0]->_build_moose_coercion }
sub compiled_coercion      { $_[0]{compiled_coercion} ||= $_[0]->_build_compiled_coercion }
sub frozen                 { $_[0]{frozen}            ||= 0 }
sub coercion_generator     { $_[0]{coercion_generator} }
sub parameters             { $_[0]{parameters} }

sub has_library            { exists $_[0]{library} }
sub has_type_constraint    { defined $_[0]{type_constraint} } # sic
sub has_coercion_generator { exists $_[0]{coercion_generator} }
sub has_parameters         { exists $_[0]{parameters} }

sub add
{
	my $class = shift;
	my ($x, $y, $swap) = @_;
	
	Types::TypeTiny::TypeTiny->check($x) and return $x->plus_fallback_coercions($y);
	Types::TypeTiny::TypeTiny->check($y) and return $y->plus_coercions($x);
	
	_croak "Attempt to add $class to something that is not a $class"
		unless blessed($x) && blessed($y) && $x->isa($class) && $y->isa($class);

	($y, $x) = ($x, $y) if $swap;

	my %opts;
	if ($x->has_type_constraint and $y->has_type_constraint and $x->type_constraint == $y->type_constraint)
	{
		$opts{type_constraint} = $x->type_constraint;
	}
	$opts{name} ||= "$x+$y";
	$opts{name} = '__ANON__' if $opts{name} eq '__ANON__+__ANON__';
	
	my $new = $class->new(%opts);
	$new->add_type_coercions( @{$x->type_coercion_map} );
	$new->add_type_coercions( @{$y->type_coercion_map} );
	return $new;
}

sub _build_display_name
{
	shift->name;
}

sub qualified_name
{
	my $self = shift;
	
	if ($self->has_library and not $self->is_anon)
	{
		return sprintf("%s::%s", $self->library, $self->name);
	}
	
	return $self->name;
}

sub is_anon
{
	my $self = shift;
	$self->name eq "__ANON__";
}

sub _clear_compiled_coercion {
	delete $_[0]{_overload_coderef};
	delete $_[0]{compiled_coercion};
}

sub freeze { $_[0]{frozen} = 1; $_[0] }

sub coerce
{
	my $self = shift;
	return $self->compiled_coercion->(@_);
}

sub assert_coerce
{
	my $self = shift;
	my $r = $self->coerce(@_);
	$self->type_constraint->assert_valid($r)
		if $self->has_type_constraint;
	return $r;
}

sub has_coercion_for_type
{
	my $self = shift;
	my $type = Types::TypeTiny::to_TypeTiny($_[0]);
	
	return "0 but true"
		if $self->has_type_constraint && $type->is_a_type_of($self->type_constraint);
	
	for my $has (@{$self->type_coercion_map})
	{
		return !!1 if Types::TypeTiny::TypeTiny->check($has) && $type->is_a_type_of($has);
	}
	
	return;
}

sub has_coercion_for_value
{
	my $self = shift;
	local $_ = $_[0];
	
	return "0 but true"
		if $self->has_type_constraint && $self->type_constraint->check(@_);
	
	my $c = $self->type_coercion_map;
	for (my $i = 0; $i <= $#$c; $i += 2)
	{
		return !!1 if $c->[$i]->check(@_);
	}
	return;
}

sub add_type_coercions
{
	my $self = shift;
	my @args = @_;
	
	_croak "Attempt to add coercion code to a Type::Coercion which has been frozen"
		if $self->frozen;
	
	while (@args)
	{
		my $type     = Types::TypeTiny::to_TypeTiny(shift @args);
		my $coercion = shift @args;
		
		_croak "Types must be blessed Type::Tiny objects"
			unless Types::TypeTiny::TypeTiny->check($type);
		_croak "Coercions must be code references or strings"
			unless Types::TypeTiny::StringLike->check($coercion) || Types::TypeTiny::CodeLike->check($coercion);
		
		push @{$self->type_coercion_map}, $type, $coercion;
	}
	
	$self->_clear_compiled_coercion;
	return $self;
}

sub _build_compiled_coercion
{
	my $self = shift;
	
	my @mishmash = @{$self->type_coercion_map};
	return sub { $_[0] } unless @mishmash;

	if ($self->can_be_inlined)
	{
		local $@;
		my $sub = eval sprintf('sub ($) { %s }', $self->inline_coercion('$_[0]'));
		die "Failed to compile coercion: $@\n\nCODE: ".$self->inline_coercion('$_[0]') if $@;
		return $sub;
	}

	# These arrays will be closed over.
	my (@types, @codes);
	while (@mishmash)
	{
		push @types, shift @mishmash;
		push @codes, shift @mishmash;
	}
	if ($self->has_type_constraint)
	{
		unshift @types, $self->type_constraint;
		unshift @codes, undef;
	}
	
	my @sub;
	
	for my $i (0..$#types)
	{
		push @sub,
			$types[$i]->can_be_inlined ? sprintf('if (%s)', $types[$i]->inline_check('$_[0]')) :
			sprintf('if ($types[%d]->check(@_))', $i);
		push @sub,
			!defined($codes[$i])
				? sprintf('  { return $_[0] }') :
			Types::TypeTiny::StringLike->check($codes[$i])
				? sprintf('  { local $_ = $_[0]; return( %s ) }', $codes[$i]) :
			sprintf('  { local $_ = $_[0]; return $codes[%d]->(@_) }', $i);
	}
	
	push @sub, 'return $_[0];';
	
	local $@;
	my $sub = eval sprintf('sub ($) { %s }', join qq[\n], @sub);
	die "Failed to compile coercion: $@\n\nCODE: @sub" if $@;
	return $sub;
}

sub can_be_inlined
{
	my $self = shift;
	my @mishmash = @{$self->type_coercion_map};
	return
		if $self->has_type_constraint
		&& !$self->type_constraint->can_be_inlined;
	while (@mishmash)
	{
		my ($type, $converter) = splice(@mishmash, 0, 2);
		return unless $type->can_be_inlined;
		return unless Types::TypeTiny::StringLike->check($converter);
	}
	return !!1;
}

sub _source_type_union
{
	my $self = shift;
	
	my @r;
	push @r, $self->type_constraint if $self->has_type_constraint;
	
	my @mishmash = @{$self->type_coercion_map};
	while (@mishmash)
	{
		my ($type) = splice(@mishmash, 0, 2);
		push @r, $type;
	}
	
	require Type::Tiny::Union;
	return "Type::Tiny::Union"->new(type_constraints => \@r, tmp => 1);
}

sub inline_coercion
{
	my $self = shift;
	my $varname = $_[0];
	
	_croak "This coercion cannot be inlined" unless $self->can_be_inlined;
	
	my @mishmash = @{$self->type_coercion_map};
	return "($varname)" unless @mishmash;
	
	my (@types, @codes);
	while (@mishmash)
	{
		push @types, shift @mishmash;
		push @codes, shift @mishmash;
	}
	if ($self->has_type_constraint)
	{
		unshift @types, $self->type_constraint;
		unshift @codes, undef;
	}
	
	my @sub;
	
	for my $i (0..$#types)
	{
		push @sub, sprintf('(%s) ?', $types[$i]->inline_check($varname));
		push @sub,
			(defined($codes[$i]) && ($varname eq '$_'))
				? sprintf('scalar(%s) :', $codes[$i]) :
			defined($codes[$i])
				? sprintf('do { local $_ = %s; scalar(%s) } :', $varname, $codes[$i]) :
			sprintf('%s :', $varname);
	}
	
	push @sub, "$varname";
	
	"@sub";
}

sub _build_moose_coercion
{
	my $self = shift;
	
	my %options = ();
	$options{type_coercion_map} = [ $self->freeze->_codelike_type_coercion_map('moose_type') ];
	$options{type_constraint}   = $self->type_constraint if $self->has_type_constraint;
	
	require Moose::Meta::TypeCoercion;
	my $r = "Moose::Meta::TypeCoercion"->new(%options);
	
	return $r;
}

sub _codelike_type_coercion_map
{
	my $self = shift;
	my $modifier = $_[0];
	
	my @orig = @{ $self->type_coercion_map };
	my @new;
	
	while (@orig)
	{
		my ($type, $converter) = splice(@orig, 0, 2);
		
		push @new, $modifier ? $type->$modifier : $type;
		
		if (Types::TypeTiny::CodeLike->check($converter))
		{
			push @new, $converter;
		}
		else
		{
			local $@;
			my $r = eval sprintf('sub { local $_ = $_[0]; %s }', $converter);
			die $@ if $@;
			push @new, $r;
		}
	}
	
	return @new;
}

sub is_parameterizable
{
	shift->has_coercion_generator;
}

sub is_parameterized
{
	shift->has_parameters;
}

sub parameterize
{
	my $self = shift;
	return $self unless @_;
	$self->is_parameterizable
		or _croak "constraint '%s' does not accept parameters", "$self";
	
	@_ = map Types::TypeTiny::to_TypeTiny($_), @_;
	
	return ref($self)->new(
		type_constraint    => $self->type_constraint,
		type_coercion_map  => [ $self->coercion_generator->($self, $self->type_constraint, @_) ],
		parameters         => \@_,
		frozen             => 1,
	);
}

sub isa
{
	my $self = shift;
	
	if ($INC{"Moose.pm"} and blessed($self) and $_[0] eq 'Moose::Meta::TypeCoercion')
	{
		return !!1;
	}
	
	if ($INC{"Moose.pm"} and blessed($self) and $_[0] =~ /^Moose/ and my $r = $self->moose_coercion->isa(@_))
	{
		return $r;
	}
	
	$self->SUPER::isa(@_);
}

sub can
{
	my $self = shift;
	
	my $can = $self->SUPER::can(@_);
	return $can if $can;
	
	if ($INC{"Moose.pm"} and blessed($self) and my $method = $self->moose_coercion->can(@_))
	{
		return sub { $method->(shift->moose_coercion, @_) };
	}
	
	return;
}

sub AUTOLOAD
{
	my $self = shift;
	my ($m) = (our $AUTOLOAD =~ /::(\w+)$/);
	return if $m eq 'DESTROY';
	
	if ($INC{"Moose.pm"} and blessed($self) and my $method = $self->moose_coercion->can($m))
	{
		return $method->($self->moose_coercion, @_);
	}
	
	_croak q[Can't locate object method "%s" via package "%s"], $m, ref($self)||$self;
}

*_compiled_type_coercion = \&compiled_coercion;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Coercion - a set of coercions to a particular target type constraint

=head1 DESCRIPTION

=head2 Constructors

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=item C<< add($c1, $c2) >>

Create a Type::Coercion from two existing Type::Coercion objects.

=back

=head2 Attributes

=over

=item C<name>

TODO.

=item C<display_name>

TODO.

=item C<library>

TODO.

=item C<type_constraint>

Weak reference to the target type constraint (i.e. the type constraint which
the output of coercion coderefs is expected to conform to).

=item C<type_coercion_map>

Arrayref of source-type/code pairs. Don't set this in the constructor; use
the C<add_type_coercions> method instead.

=item C<< compiled_coercion >>

Coderef to coerce a value (C<< $_[0] >>).

The general point of this attribute is that you should not set it, and
rely on the lazily-built default. Type::Coerce will usually generate a
pretty fast coderef, inlining all type constraint checks, etc.

=item C<moose_coercion>

A L<Moose::Meta::TypeCoercion> object equivalent to this one. Don't set this
manually; rely on the default built one.

=item C<frozen>

Boolean; default false. A frozen coercion cannot have C<add_type_coercions>
called upon it.

=back

=head2 Methods

=over

=item C<has_type_constraint>, C<has_library>

Predicate methods.

=item C<is_anon>

TODO.

=item C<< qualified_name >>

For non-anonymous coercions that have a library, returns a qualified
C<< "Library::Type" >> sort of name. Otherwise, returns the same as C<name>.

=item C<< add_type_coercions($type1, $code1, ...) >>

Takes one or more pairs of L<Type::Tiny> constraints and coercion code,
creating an ordered list of source types and coercion codes.

Coercion codes can be expressed as either a string of Perl code (this
includes objects which overload stringification), or a coderef (or object
that overloads coderefification). In either case, the value to be coerced
is C<< $_ >>.

=item C<< coerce($value) >>

Coerce the value to the target type.

=item C<< assert_coerce($value) >>

Coerce the value to the target type, and throw an exception if the result
does not validate against the target type constraint.

=item C<< has_coercion_for_type($source_type) >>

Returns true iff this coercion has a coercion from the source type.

Returns the special string C<< "0 but true" >> if no coercion would be
actually be necessary for this type.

=item C<< has_coercion_for_value($value) >>

Returns true iff the value could be coerced by this coercion.

Returns the special string C<< "0 but true" >> if no coercion would be
actually be necessary for this value (due to it already meeting the target
type constraint).

=item C<< can_be_inlined >>

Returns true iff the coercion can be inlined.

=item C<< inline_coercion($varname) >>

Much like C<inline_coerce> from L<Type::Tiny>.

=item C<< freeze >>

Set C<frozen> to true. There is no C<unfreeze>. Called automatically by
L<Type::Tiny> sometimes.

=item C<< isa($class) >>, C<< can($method) >>, C<< AUTOLOAD(@args) >>

If Moose is loaded, then the combination of these methods is used to mock
a Moose::Meta::TypeCoercion.

=back

The following methods are used for parameterized coercions, but are not
fully documented because they may change in the near future:

=over

=item C<< coercion_generator >>

=item C<< has_coercion_generator >>

=item C<< has_parameters >>

=item C<< is_parameterizable >>

=item C<< is_parameterized >>

=item C<< parameterize(@params) >>

=item C<< parameters >>

=back

=head2 Overloading

=over

=item *

Boolification is overloaded to always return true.

=item *

Coderefification is overloaded to call C<coerce>.

=item *

On Perl 5.10.1 and above, smart match is overloaded to call C<has_coercion_for_value>.

=item *

Addition is overloaded to call C<add>.

=back

=head1 DIAGNOSTICS

=over

=item B<< Attempt to add coercion code to a Type::Coercion which has been frozen >>

Type::Tiny type constraints are designed as immutable objects. Once you've
created a constraint, rather than modifying it you generally create child
constraints to do what you need.

Type::Coercion objects, on the other hand, are mutable. Coercion routines
can be added at any time during the object's lifetime.

Sometimes Type::Tiny needs to freeze a Type::Coercion object to prevent this.
In L<Moose> and L<Mouse> code this is likely to happen as soon as you use a
type constraint in an attribute.

Workarounds:

=over

=item *

Define as many of your coercions as possible within type libraries, not
within the code that uses the type libraries. The type library will be
evaluated relatively early, likely before there is any reason to freeze
a coercion.

=item *

If you do need to add coercions to a type within application code outside
the type library, instead create a subtype and add coercions to that. The
C<plus_coercions> method provided by L<Type::Tiny> should make this simple.

=back

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Library>, L<Type::Utils>, L<Types::Standard>.

L<Type::Coercion::Union>.

L<Moose::Meta::TypeCoercion>.

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


