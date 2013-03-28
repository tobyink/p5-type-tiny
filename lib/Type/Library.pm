package Type::Library;

use 5.008003;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.001';
}

use Scalar::Util qw< blessed >;
use Type::Tiny;

sub _confess ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::confess;
}

{
	my $got_subname;
	sub _subname ($$)
	{
		$got_subname = 1 && goto \&Sub::Name::subname
			if $got_subname || eval "require Sub::Name";
		return $_[1];
	}
}

sub import
{
	my $meta             = shift->meta;
	my ($opts, @exports) = $meta->_process_tags(@_);
	$opts->{caller}      = caller;
	$meta->_export($_, $opts) for @exports;
}

sub _process_tags
{
	my $meta = shift; # private; no need for ->meta
	my @args = @_;
	my ($opts, @exports) = ({});
	
	while (defined(my $arg = shift @args))
	{
		my %arg_opts = ref $args[0] ? %{shift @args} : ();
		my $optify   = sub {+{ sub => $_[0], %arg_opts }};
		
		if ($arg =~ /^[:-]moose$/i)
			{ $opts->{moose} = 1 }
		elsif ($arg =~ /^[:-]all$/i)
			{ push @exports, map $optify->($_), map { $_, "is_$_", "to_$_", "assert_$_" } $meta->type_names }
		elsif ($arg =~ /^[:-](assert|is|to)$/i)
			{ push @exports, map $optify->($_), map "$1\_$_", $meta->type_names }
		elsif ($arg =~ /^[:-]types$/i)
			{ push @exports, map $optify->($_), $meta->type_names }
		elsif ($arg =~ /^\+(.+)$/i)
			{ push @exports, map $optify->($_), map { $_, "is_$_", "to_$_", "assert_$_" } $1 }
		else
			{ push @exports, map $optify->($_), $arg }
	}
	
	return ($opts, @exports);
}

sub _export
{
	my $meta = shift; # private; no need for ->meta
	my ($sub, $opts) = @_;
	my $class = blessed($meta);
	
	my $type;
	my $export_coderef;
	my $export_as        = $sub->{sub};
	my $export_to        = $opts->{caller};
	
	if ($sub->{sub} =~ /^(is|to|assert)_/ and my $coderef = $class->can($sub->{sub}))
		{ $export_coderef = $coderef }
	elsif ($opts->{moose} and $type = $meta->get_type($sub->{sub}))
		{ $export_coderef = _subname $type->qualified_name, sub (;$) { (@_ ? $type->parameterize(@{$_[0]}) : $type)->as_moose } }
	elsif ($type = $meta->get_type($sub->{sub}))
		{ $export_coderef = _subname $type->qualified_name, sub (;$) { (@_ ? $type->parameterize(@{$_[0]}) : $type) } }
	else
		{ _confess "'%s' is not exported by '%s'", $sub->{sub}, $class }
	
	$export_as = $sub->{-as}                if exists $sub->{-as};
	$export_as = $sub->{-prefix}.$export_as if exists $sub->{-prefix};
	$export_as = $export_as.$sub->{-suffix} if exists $sub->{-suffix};
	
	my $export_fullname = join("::", $export_to, $export_as);
	
	no strict "refs";
	*{$export_fullname} = $export_coderef;
}

sub meta
{
	no strict "refs";
	no warnings "once";
	return $_[0] if blessed $_[0];
	${"$_[0]\::META"} ||= bless {}, $_[0];
}

sub add_type
{
	my $meta = shift->meta;
	my $type = blessed($_[0]) ? $_[0] : ref($_[0]) ? "Type::Tiny"->new($_[0]) : "Type::Tiny"->new(@_);
	my $name = $type->name;
	
	$meta->{types} ||= {};
	_confess 'type %s already exists in this library', $name if exists $meta->{types}{$name};
	_confess 'cannot add anonymous type to a library' if $type->is_anon;
	$meta->{types}{$name} = $type;
	
	no strict "refs";
	my $class = blessed($meta);
	*{"$class\::$name"   }     = _subname $type->qualified_name, sub (;$) { $type };
	*{"$class\::is_$name"}     = _subname $type->qualified_name, sub ($)  { $type->check($_[0]) };
	*{"$class\::to_$name"}     = _subname $type->qualified_name, sub ($)  { $type->coerce($_[0]) };
	*{"$class\::assert_$name"} = _subname $type->qualified_name, sub ($)  { $type->assert_valid($_[0]) };
	return $type;
}

sub get_type
{
	my $meta = shift->meta;
	$meta->{types}{$_[0]};
}

sub has_type
{
	my $meta = shift->meta;
	exists $meta->{types}{$_[0]};
}

sub type_names
{
	my $meta = shift->meta;
	keys %{ $meta->{types} };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Library - tiny, yet Moo(se)-compatible type libraries

=head1 SYNOPSIS

	package MyTypes {
		use Scalar::Util qw(looks_like_number);
		use base "Type::Library";
		use Type::Tiny;
		
		my $NUM = "Type::Tiny"->new(
			name       => "Number",
			constraint => sub { looks_like_number($_) },
			message    => sub { "$_ ain't a number" },
		);
		
		__PACKAGE__->meta->add_type($NUM);
	}
		
	package Ermintrude {
		use Moo;
		use MyTypes qw(Number);
		has favourite_number => (is => "ro", isa => Number);
	}
	
	# Note the "-moose" flag when importing!
	package Bullwinkle {
		use Moose;
		use MyTypes -moose, qw(Number);
		has favourite_number => (is => "ro", isa => Number);
	}

=head1 DESCRIPTION

L<Type::Library> is a tiny class for creating MooseX::Types-like type
libraries which are compatible with Moo and Moose.

If you're reading this because you want to create a type library, then
you're probably better off reading L<Type::Tiny::Intro>.

=head2 Methods

A type library is a singleton class. Use the C<meta> method to get a blessed
object which other methods can get called on. For example:

	MyTypes->meta->add_type($foo);

=over

=item C<< add_type($type) >> or C<< add_type(%opts) >>

Add a type to the library. If C<< %opts >> is given, then this method calls
C<< Type::Tiny->new(%opts) >> first, and adds the resultant type.

Adding a type named "Foo" to the library will automatically define four
functions in the library's namespace:

=over

=item C<< Foo >>

Returns the Type::Tiny object.

=item C<< is_Foo($value) >>

Returns true iff $value passes the type contraint.

=item C<< assert_Foo($value) >>

Returns true iff $value passes the type contraint. Dies otherwise.

=item C<< to_Foo($value) >>

Coerces the value to the type. (Not implemented yet.)

=back

=item C<< get_type($name) >>

Gets the C<Type::Tiny> object corresponding to the name.

=item C<< has_type($name) >>

Boolean; returns true if the type exists in the library.

=item C<< type_names >>

List all types defined by the library.

=item C<< import(@args) >>

Type::Library-based libraries are exporters.

=back

=head2 Export

Not yet documented.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Intro>, L<Type::Library>, L<Type::Library::Util>.

L<Moose::Meta::TypeConstraint>.

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

