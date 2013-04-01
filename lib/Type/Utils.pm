package Type::Utils;

use 5.008001;
use strict;
use warnings;

sub _confess ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

use Scalar::Util qw< blessed >;
use Type::Library;
use Type::Tiny;

use Exporter qw< import >;
our @EXPORT = qw< 
	extends declare as where message inline_as
	class_type role_type duck_type union intersection enum
	coerce from via
>;
our @EXPORT_OK = (@EXPORT, qw< type subtype >);

sub extends
{
	_confess "not a type library" unless caller->isa("Type::Library");
	my $caller = caller->meta;
	
	foreach my $lib (@_)
	{
		eval "require $lib" or _confess "could not load library '$lib': $@";
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
		_confess "cannot provide two names for type" if exists $opts{name};
		$opts{name} = $name;
	}

	my $caller = caller($opts{_caller_level} || 0);
	$opts{library} = $caller;

	if (defined $opts{parent} and not blessed $opts{parent})
	{
		$caller->isa("Type::Library")
			or _confess "parent type cannot be a string";
		$opts{parent} = $caller->meta->get_type($opts{parent})
			or _confess "could not find parent type";
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

sub as ($;@)
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
	my $coderef = shift;
	inlined => sub { local $_ = $_[1]; $coderef->(@_) }, @_;
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

sub coerce
{
	my $meta = (scalar caller)->meta;
	
	if ((scalar caller)->isa("Type::Library"))
	{
		my ($type, @opts) = map { ref($_) ? $_ : $meta->get_type($_) } @_;
		return $type->coercion->add_type_coercions(@opts);
	}

	my ($type, @opts) = @_;
	return $type->coercion->add_type_coercions(@opts);
}

sub from ($;@)
{
	return @_;
}

sub via (&;@)
{
	return @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Utils - utility functions to make defining type constraints a little easier

=head1 SYNOPSIS

   package MyTypes;
   
   use base "Type::Library";
   use Type::Utils;
   
   extends "Type::Standard";
   
   declare "AllCaps",
      as "Str",
      where { uc($_) eq $_ },
      inline_as { my $varname = $_[1]; "uc($varname) eq $varname" };
   
   coerce "AllCaps",
      from "Str", via { uc($_) };

=head1 DESCRIPTION

This module provides utility functions to make defining type constraints a
little easier. By default, all of the functions documented below are
exported, except C<subtype> and C<type> (use C<declare> instead).

=head2 Moose::Util::TypeConstraints-like

The following are similar to the similarly named functions described in
L<Moose::Util::TypeConstraints>.

=over

=item C<< subtype $name, %options >>

=item C<< subtype %options >>

=item C<< type $name, %options >>

=item C<< type %options >>

=item C<< as $parent >>

=item C<< where { BLOCK } >>

=item C<< message { BLOCK } >>

=item C<< inline_as { BLOCK } >>

=item C<< class_type $name, { class => $package, %options } >>

=item C<< class_type { class => $package, %options } >>

=item C<< role_type $name, { role => $package, %options } >>

=item C<< role_type { role => $package, %options } >>

=item C<< duck_type $name, \@methods >>

=item C<< duck_type \@methods >>

=item C<< union $name, \@constraints >>

=item C<< union \@constraints >>

=item C<< enum $name, \@values >>

=item C<< enum \@values >>

=item C<< coerce $target, @coercions >>

=item C<< from $source >>

=item C<< via { BLOCK } >>

=back

=head2 Other

=over

=item C<< declare $name, %options >>

=item C<< declare %options >>

C<declare> is a function which works like C<subtype> and C<type>. In fact,
the latter pair are just aliases for the former.

=item C<< intersection $name, \@constraints >>

=item C<< intersection \@constraints >>

Defines a type constraint which is the intersection of several existing
constraints.

=item C<< extends @library >>

Indicates that this type library extends other type libraries, importing
their type constraints.

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

