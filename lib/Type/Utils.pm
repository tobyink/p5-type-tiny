package Type::Utils;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Type::Utils::AUTHORITY = 'cpan:TOBYINK';
	$Type::Utils::VERSION   = '0.021_01';
}

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

use Scalar::Util qw< blessed >;
use Type::Library;
use Type::Tiny;
use Types::TypeTiny qw< TypeTiny to_TypeTiny HashLike StringLike CodeLike >;

our @EXPORT = qw<
	declare as where message inline_as
	class_type role_type duck_type union intersection enum
	coerce from via
	declare_coercion to_type
>;
our @EXPORT_OK = (
	@EXPORT,
	qw<
		extends type subtype
		match_on_type compile_match_on_type
		dwim_type
	>,
);

use base qw< Exporter::TypeTiny >;

sub extends
{
	_croak "Not a type library" unless caller->isa("Type::Library");
	my $caller = caller->meta;
	
	foreach my $lib (@_)
	{
		eval "require $lib" or _croak "Could not load library '$lib': $@";
		$caller->add_type($lib->get_type($_)) for $lib->meta->type_names;
	}
}

sub declare
{
	my %opts;
	if (@_ % 2 == 0)
	{
		%opts = @_;
	}
	else
	{
		(my($name), %opts) = @_;
		_croak "Cannot provide two names for type" if exists $opts{name};
		$opts{name} = $name;
	}
	
	my $caller = caller($opts{_caller_level} || 0);
	$opts{library} = $caller;
	
	if (defined $opts{parent})
	{
		$opts{parent} = to_TypeTiny($opts{parent});
		
		unless (TypeTiny->check($opts{parent}))
		{
			$caller->isa("Type::Library")
				or _croak("Parent type cannot be a %s", ref($opts{parent})||'non-reference scalar');
			$opts{parent} = $caller->meta->get_type($opts{parent})
				or _croak("Could not find parent type");
		}
	}
	
	my $type;
	if (defined $opts{parent})
	{
		$type = delete($opts{parent})->create_child_type(%opts);
	}
	else
	{
		my $bless = delete($opts{bless}) || "Type::Tiny";
		eval "require $bless";
		$type = $bless->new(%opts);
	}
	
	if ($caller->isa("Type::Library"))
	{
		$caller->meta->add_type($type) unless $type->is_anon;
	}
	
	return $type;
}

*subtype = \&declare;
*type = \&declare;

sub as (@)
{
	parent => @_;
}

sub where (&;@)
{
	constraint => @_;
}

sub message (&;@)
{
	message => @_;
}

sub inline_as (&;@)
{
	inlined => @_;
}

sub class_type
{
	my $name = ref($_[0]) ? undef : shift;
	my %opts = %{ +shift };
	
	if (defined $name)
	{
		$opts{name}  = $name unless exists $opts{name};
		$opts{class} = $name unless exists $opts{class};
	}
	
	$opts{bless} = "Type::Tiny::Class";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub role_type
{
	my $name = ref($_[0]) ? undef : shift;
	my %opts = %{ +shift };
	
	if (defined $name)
	{
		$opts{name}  = $name unless exists $opts{name};
		$opts{role}  = $name unless exists $opts{role};
	}
	
	$opts{bless} = "Type::Tiny::Role";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub duck_type
{
	my $name    = ref($_[0]) ? undef : shift;
	my @methods = @{ +shift };
	
	my %opts;
	$opts{name} = $name if defined $name;
	$opts{methods} = \@methods;
	
	$opts{bless} = "Type::Tiny::Duck";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub enum
{
	my $name   = ref($_[0]) ? undef : shift;
	my @values = @{ +shift };
	
	my %opts;
	$opts{name} = $name if defined $name;
	$opts{values} = \@values;
	
	$opts{bless} = "Type::Tiny::Enum";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub union
{
	my $name = ref($_[0]) ? undef : shift;
	my @tcs  = @{ +shift };
	
	my %opts;
	$opts{name} = $name if defined $name;
	$opts{type_constraints} = \@tcs;
	
	$opts{bless} = "Type::Tiny::Union";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub intersection
{
	my $name = ref($_[0]) ? undef : shift;
	my @tcs  = @{ +shift };
	
	my %opts;
	$opts{name} = $name if defined $name;
	$opts{type_constraints} = \@tcs;
	
	$opts{bless} = "Type::Tiny::Intersection";
	
	{ no warnings "numeric"; $opts{_caller_level}++ }
	declare(%opts);
}

sub declare_coercion
{
	my %opts;
	$opts{name} = shift if !ref($_[0]);
	
	while (HashLike->check($_[0]) and not TypeTiny->check($_[0]))
	{
		%opts = (%opts, %{+shift});
	}
	
	my $caller = caller($opts{_caller_level} || 0);
	$opts{library} = $caller;
	
	my $bless = delete($opts{bless}) || "Type::Coercion";
	eval "require $bless";
	my $c = $bless->new(%opts);
	
	my @C;
	
	if ($caller->isa("Type::Library"))
	{
		my $meta = $caller->meta;
		$meta->add_coercion($c) unless $c->is_anon;
		while (@_)
		{
			push @C, map { ref($_) ? to_TypeTiny($_) : $meta->get_type($_)||$_ } shift;
			push @C, shift;
		}
	}
	
	$c->add_type_coercions(@C);
	
	return $c->freeze;
}

sub coerce
{
	if ((scalar caller)->isa("Type::Library"))
	{
		my $meta = (scalar caller)->meta;
		my ($type) = map { ref($_) ? to_TypeTiny($_) : $meta->get_type($_)||$_ } shift;
		my @opts;
		while (@_)
		{
			push @opts, map { ref($_) ? to_TypeTiny($_) : $meta->get_type($_)||$_ } shift;
			push @opts, shift;
		}
		return $type->coercion->add_type_coercions(@opts);
	}
	
	my ($type, @opts) = @_;
	$type = to_TypeTiny($type);
	return $type->coercion->add_type_coercions(@opts);
}

sub from (@)
{
	return @_;
}

sub to_type (@)
{
	my $type = shift;
	unless (TypeTiny->check($type))
	{
		caller->isa("Type::Library")
			or _croak "Target type cannot be a string";
		$type = caller->meta->get_type($type)
			or _croak "Could not find target type";
	}
	return +{ type_constraint => $type }, @_;
}

sub via (&;@)
{
	return @_;
}

sub match_on_type
{
	my $value = shift;
	
	while (@_)
	{
		my ($type, $code);
		if (@_ == 1)
		{
			require Types::Standard;
			($type, $code) = (Types::Standard::Any(), shift);
		}
		else
		{
			($type, $code) = splice(@_, 0, 2);
			TypeTiny->($type);
		}
		
		$type->check($value) or next;
		
		if (StringLike->check($code))
		{
			local $_ = $value;
			if (wantarray) {
				my @r = eval "$code";
				die $@ if $@;
				return @r;
			}
			if (defined wantarray) {
				my $r = eval "$code";
				die $@ if $@;
				return $r;
			}
			eval "$code";
			die $@ if $@;
			return;
		}
		else
		{
			CodeLike->($code);
			local $_ = $value;
			return $code->($value);
		}
	}
	
	_croak("No cases matched for %s", Type::Tiny::_dd($value));
}

sub compile_match_on_type
{
	my @code = 'sub { local $_ = $_[0]; ';
	my @checks;
	my @actions;
	
	my $els = '';
	
	while (@_)
	{
		my ($type, $code);
		if (@_ == 1)
		{
			require Types::Standard;
			($type, $code) = (Types::Standard::Any(), shift);
		}
		else
		{
			($type, $code) = splice(@_, 0, 2);
			TypeTiny->($type);
		}
		
		if ($type->can_be_inlined)
		{
			push @code, sprintf('%sif (%s)', $els, $type->inline_check('$_'));
		}
		else
		{
			push @checks, $type;
			push @code, sprintf('%sif ($checks[%d]->check($_))', $els, $#checks);
		}
		
		$els = 'els';
		
		if (StringLike->check($code))
		{
			push @code, sprintf('  { %s }', $code);
		}
		else
		{
			CodeLike->($code);
			push @actions, $code;
			push @code, sprintf('  { $actions[%d]->(@_) }', $#actions);
		}
	}
	
	push @code, 'else', '  { Type::Util::_croak("No cases matched for %s", Type::Tiny::_dd($_[0])) }';
	
	push @code, '}';  # /sub
	
	require Eval::TypeTiny;
	return Eval::TypeTiny::eval_closure(
		source      => \@code,
		environment => {
			'@actions' => \@actions,
			'@checks'  => \@checks,
		},
	);
}

{
	package #hide
	Type::Registry::DWIM;
	
	our @ISA = qw(Type::Registry);
	
	sub simple_lookup
	{
		my $self = shift;
		my $r;
		
		# If the lookup is chained to a class, then the class' own
		# type registry gets first refusal.
		#
		if (defined $self->{"~~chained"})
		{
			my $chained = "Type::Registry"->for_class($self->{"~~chained"});
			$r = eval { $chained->simple_lookup(@_) } unless $self == $chained;
			return $r if defined $r;
		}
		
		# Fall back to types in Types::Standard.
		require Types::Standard;
		return 'Types::Standard'->get_type($_[0]) if 'Types::Standard'->has_type($_[0]);
		
		# Only continue any further if we've been called from Type::Parser.
		return unless $_[1];
		
		# If Moose is loaded...
		if ($INC{'Moose.pm'})
		{
			require Moose::Util::TypeConstraints;
			require Types::TypeTiny;
			$r = Moose::Util::TypeConstraints::find_type_constraint($_[0]);
			return Types::TypeTiny::to_TypeTiny($r) if defined $r;
		}
		
		# If Mouse is loaded...
		if ($INC{'Mouse.pm'})
		{
			require Mouse::Util::TypeConstraints;
			require Types::TypeTiny;
			$r = Mouse::Util::TypeConstraints::find_type_constraint($_[0]);
			return Types::TypeTiny::to_TypeTiny($r) if defined $r;
		}
		
		return unless $_[0] =~ /^\s*(\w+(::\w+)*)\s*$/sm;
		return unless defined $self->{"~~assume"};
		
		# Lastly, if it looks like a class/role name, assume it's
		# supposed to be a class/role type.
		#
		
		if ($self->{"~~assume"} eq "Type::Tiny::Class")
		{
			require Type::Tiny::Class;
			return "Type::Tiny::Class"->new(class => $_[0]);
		}
		
		if ($self->{"~~assume"} eq "Type::Tiny::Role")
		{
			require Type::Tiny::Role;
			return "Type::Tiny::Role"->new(role => $_[0]);
		}
		
		die;
	}
}

our $dwimmer;
sub dwim_type
{
	my ($string, %opts) = @_;
	$opts{for} = caller unless defined $opts{for};
	
	$dwimmer ||= do {
		require Type::Registry;
		'Type::Registry::DWIM'->new;
	};
	
	local $dwimmer->{'~~chained'} = $opts{for};
	local $dwimmer->{'~~assume'}  = $opts{does} ? 'Type::Tiny::Role' : 'Type::Tiny::Class';
	
	$dwimmer->lookup($string);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords smush smushed

=head1 NAME

Type::Utils - utility functions to make defining and using type constraints a little easier

=head1 SYNOPSIS

   package Types::Mine;
   
   use Type::Library -base;
   use Type::Utils -all;
   
   BEGIN { extends "Types::Standard" };
   
   declare "AllCaps",
      as "Str",
      where { uc($_) eq $_ },
      inline_as { my $varname = $_[1]; "uc($varname) eq $varname" };
   
   coerce "AllCaps",
      from "Str", via { uc($_) };

=head1 DESCRIPTION

This module provides utility functions to make defining and using type
constraints a little easier. 

=head2 Type declaration functions

Many of the following are similar to the similarly named functions described
in L<Moose::Util::TypeConstraints>.

=over

=item C<< declare $name, %options >>

=item C<< declare %options >>

Declare a named or anonymous type constraint. Use C<as> and C<where> to
specify the parent type (if any) and (possibly) refine its definition.

   declare EvenInt, as Int, where { $_ % 2 == 0 };

   my $EvenInt = declare as Int, where { $_ % 2 == 0 };

B<< NOTE: >>
If the caller package inherits from L<Type::Library> then any non-anonymous
types declared in the package will be automatically installed into the
library.

Hidden gem: if you're inheriting from a type constraint that includes some
coercions, you can include C<< coerce => 1 >> in the C<< %options >> hash
to inherit the coercions.

=item C<< subtype $name, %options >>

=item C<< subtype %options >>

Declare a named or anonymous type constraint which is descended from an
existing type constraint. Use C<as> and C<where> to specify the parent
type and refine its definition.

Actually, you should use C<declare> instead; this is just an alias.

This function is not exported by default.

=item C<< type $name, %options >>

=item C<< type %options >>

Declare a named or anonymous type constraint which is not descended from
an existing type constraint. Use C<where> to provide a coderef that
constrains values.

Actually, you should use C<declare> instead; this is just an alias.

This function is not exported by default.

=item C<< as $parent >>

Used with C<declare> to specify a parent type constraint:

   declare EvenInt, as Int, where { $_ % 2 == 0 };

=item C<< where { BLOCK } >>

Used with C<declare> to provide the constraint coderef:

   declare EvenInt, as Int, where { $_ % 2 == 0 };

The coderef operates on C<< $_ >>, which is the value being tested.

=item C<< message { BLOCK } >>

Generate a custom error message when a value fails validation.

   declare EvenInt,
      as Int,
      where { $_ % 2 == 0 },
      message {
         Int->validate($_) or "$_ is not divisible by two";
      };

Without a custom message, the messages generated by Type::Tiny are along
the lines of I<< Value "33" did not pass type constraint "EvenInt" >>,
which is usually reasonable.

=item C<< inline_as { BLOCK } >>

Generate a string of Perl code that can be used to inline the type check into
other functions. If your type check is being used within a L<Moose> or L<Moo>
constructor or accessor methods, or used by L<Type::Params>, this can lead to
significant performance improvements.

   declare EvenInt,
      as Int,
      where { $_ % 2 == 0 },
      inline_as {
         my ($constraint, $varname) = @_;
         my $perlcode = 
            $constraint->parent->inline_check($varname)
            . "&& ($varname % 2 == 0)";
         return $perlcode;
      };
   
   warn EvenInt->inline_check('$xxx');  # demonstration

B<Experimental:> your C<inline_as> block can return a list, in which case
these will be smushed together with "&&". The first item on the list may
be undef, in which case the undef will be replaced by the inlined parent
type constraint. (And will throw an exception if there is no parent.)

   declare EvenInt,
      as Int,
      where { $_ % 2 == 0 },
      inline_as {
         return (undef, "($_ % 2 == 0)");
      };

Returning a list like this is considered experimental, is not tested very
much, and I offer no guarantees that it will necessarily work with
Moose/Mouse/Moo.

=item C<< class_type $name, { class => $package, %options } >>

=item C<< class_type { class => $package, %options } >>

Shortcut for declaring a L<Type::Tiny::Class> type constraint.

=item C<< role_type $name, { role => $package, %options } >>

=item C<< role_type { role => $package, %options } >>

Shortcut for declaring a L<Type::Tiny::Role> type constraint.

=item C<< duck_type $name, \@methods >>

=item C<< duck_type \@methods >>

Shortcut for declaring a L<Type::Tiny::Duck> type constraint.

=item C<< union $name, \@constraints >>

=item C<< union \@constraints >>

Shortcut for declaring a L<Type::Tiny::Union> type constraint.

=item C<< enum $name, \@values >>

=item C<< enum \@values >>

Shortcut for declaring a L<Type::Tiny::Enum> type constraint.

=item C<< intersection $name, \@constraints >>

=item C<< intersection \@constraints >>

Shortcut for declaring a L<Type::Tiny::Intersection> type constraint.

=back

=head2 Coercion declaration functions

Many of the following are similar to the similarly named functions described
in L<Moose::Util::TypeConstraints>.

=over

=item C<< coerce $target, @coercions >>

Add coercions to the target type constraint. The list of coercions is a
list of type constraint, conversion code pairs. Conversion code can be
either a string of Perl code or a coderef; in either case the value to
be converted is C<< $_ >>.

=item C<< from $source >>

Sugar to specify a type constraint in a list of coercions:

   coerce EvenInt, from Int, via { $_ * 2 };  # As a coderef...
   coerce EvenInt, from Int, q { $_ * 2 };    # or as a string!

=item C<< via { BLOCK } >>

Sugar to specify a coderef in a list of coercions.

=item C<< declare_coercion $name, \%opts, $type1, $code1, ... >>

=item C<< declare_coercion \%opts, $type1, $code1, ... >>

Declares a coercion that is not explicitly attached to any type in the
library. For example:

   declare_coercion "ArrayRefFromAny", from "Any", via { [$_] };

This coercion will be exportable from the library as a L<Type::Coercion>
object, but the ArrayRef type exported by the library won't automatically
use it.

Coercions declared this way are immutable (frozen).

=item C<< to_type $type >>

Used with C<declare_coercion> to declare the target type constraint for
a coercion, but still without explicitly attaching the coercion to the
type constraint:

   declare_coercion "ArrayRefFromAny",
      to_type "ArrayRef",
      from "Any", via { [$_] };

You should pretty much always use this when declaring an unattached
coercion because it's exceedingly useful for a type coercion to know what
it will coerce to - this allows it to skip coercion when no coercion is
needed (e.g. avoiding coercing C<< [] >> to C<< [ [] ] >>) and allows
C<assert_coerce> to work properly.

=back

=head2 Type library management

=over

=item C<< extends @libraries >>

Indicates that this type library extends other type libraries, importing
their type constraints.

Should usually be executed in a C<< BEGIN >> block.

This is not exported by default because it's not fun to export it to Moo,
Moose or Mouse classes! C<< use Type::Utils -all >> can be used to import
it into your type library.

=back

=head2 Other

=over

=item C<< match_on_type $value => ($type => \&action, ..., \&default?) >>

Something like a C<switch>/C<case> or C<given>/C<when> construct. Dispatches
along different code paths depending on the type of the incoming value.
Example blatantly stolen from the Moose documentation:

   sub to_json
   {
      my $value = shift;
      
      return match_on_type $value => (
         HashRef() => sub {
            my $hash = shift;
            '{ '
               . (
               join ", " =>
               map { '"' . $_ . '" : ' . to_json( $hash->{$_} ) }
               sort keys %$hash
            ) . ' }';
         },
         ArrayRef() => sub {
            my $array = shift;
            '[ '.( join ", " => map { to_json($_) } @$array ).' ]';
         },
         Num()   => q {$_},
         Str()   => q { '"' . $_ . '"' },
         Undef() => q {'null'},
         => sub { die "$_ is not acceptable json type" },
      );
   }

Note that unlike Moose, code can be specified as a string instead of a
coderef. (e.g. for C<Num>, C<Str> and C<Undef> above.)

For improved performance, try C<compile_match_on_type>.

This function is not exported by default.

=item C<< my $coderef = compile_match_on_type($type => \&action, ..., \&default?) >>

Compile a C<match_on_type> block into a coderef. The following JSON
converter is about two orders of magnitude faster than the previous
example:

   sub to_json;
   *to_json = compile_match_on_type(
      HashRef() => sub {
         my $hash = shift;
         '{ '
            . (
            join ", " =>
            map { '"' . $_ . '" : ' . to_json( $hash->{$_} ) }
            sort keys %$hash
         ) . ' }';
      },
      ArrayRef() => sub {
         my $array = shift;
         '[ '.( join ", " => map { to_json($_) } @$array ).' ]';
      },
      Num()   => q {$_},
      Str()   => q { '"' . $_ . '"' },
      Undef() => q {'null'},
      => sub { die "$_ is not acceptable json type" },
   );

Remember to store the coderef somewhere fairly permanent so that you
don't compile it over and over. C<state> variables (in Perl >= 5.10)
are good for this. (Same sort of idea as L<Type::Params>.)

This function is not exported by default.

=item C<< dwim_type($string, %options) >>

Given a string like "ArrayRef[Int|CodeRef]", turns it into a type constraint
object, hopefully doing what you mean.

It uses the syntax of L<Type::Parser>. Firstly the L<Type::Registry>
for the caller package is consulted; if that doesn't have a match,
L<Types::Standard> is consulted for type constraint names; and if
there's still no match, then if a type constraint looks like a class
name, a new L<Type::Tiny::Class> object is created for it.

Somewhere along the way, it also checks Moose/Mouse's type constraint
registries if they are loaded.

You can specify an alternative for the caller using the C<for> option.
If you'd rather create a L<Type::Tiny::Role> object, set the C<does>
option to true.

   # An arrayref of objects, each of which must do role Foo.
   my $type = dwim_type("ArrayRef[Foo]", does => 1);
   
   Type::Registry->for_me->add_types("-Standard");
   Type::Registry->for_me->alias_type("Int" => "Foo");
   
   # An arrayref of integers.
   my $type = dwim_type("ArrayRef[Foo]", does => 1);

While it's probably better overall to use the proper L<Type::Registry>
interface for resolving type constraint strings, this function often does
what you want.

It should never die if it fails to find a type constraint (but may die
if the type constraint string is syntactically malformed), preferring to
return undef.

This function is not exported by default.

=back

=head1 EXPORT

By default, all of the functions documented above are exported, except
C<subtype> and C<type> (prefer C<declare> instead), C<extends>, C<dwim_type>,
and C<match_on_type>/C<compile_match_on_type>.

This module uses L<Exporter::TypeTiny>; see the documentation of that module
for tips and tricks importing from Type::Utils.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Library>, L<Types::Standard>, L<Type::Coercion>.

L<Type::Tiny::Class>, L<Type::Tiny::Role>, L<Type::Tiny::Duck>,
L<Type::Tiny::Enum>, L<Type::Tiny::Union>.

L<Moose::Util::TypeConstraints>,
L<Mouse::Util::TypeConstraints>.

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

