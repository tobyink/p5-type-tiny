package Type::Library;

use 5.008003;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::VERSION   = '0.000_07';
}

use Scalar::Util qw< blessed >;
use Type::Tiny;
use Types::TypeTiny qw< TypeTiny >;

sub _croak ($;@)
{
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
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
	no strict 'refs';
	push @{"$opts->{caller}\::ISA"}, ref($meta) if $opts->{base};
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
		elsif ($arg =~ /^[:-]mouse$/i)
			{ $opts->{mouse} = 1 }
		elsif ($arg =~ /^[:-]declare$/i)
			{ $opts->{declare} = 1 }
		elsif ($arg =~ /^[:-]base/i)
			{ $opts->{base} = 1 }
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

sub _EXPORT_OK
{
	no strict "refs";
	my $class = shift;
	@{"$class\::EXPORT_OK"};
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
	{
		$export_coderef = $coderef;
	}
	
	elsif ($opts->{declare} and $export_to->isa("Type::Library"))
	{
		$export_coderef = sub (;@)
		{
			my $params; $params = shift if ref($_[0]) eq "ARRAY";
			my $type = $export_to->get_type($sub->{sub});
			unless ($type)
			{
				_croak "cannot parameterize a non-existant type" if $params;
				$type = $sub->{sub};
			}
			
			my $t = $params ? $type->parameterize(@$params) : $type;
			@_ && wantarray ? return($t, @_) : return $t;
		};
	}
	
	elsif ($opts->{moose} and $type = $meta->get_type($sub->{sub}))
	{
		$export_coderef = _subname $type->qualified_name, sub (;@)
		{
			my $params; $params = shift if ref($_[0]) eq "ARRAY";
			my $t = $params ? $type->parameterize(@$params) : $type;
			@_ && wantarray ? return($t->moose_type, @_) : return $t->moose_type;
		}
	}
	
	elsif ($opts->{mouse} and $type = $meta->get_type($sub->{sub}))
	{
		$export_coderef = _subname $type->qualified_name, sub (;@)
		{
			my $params; $params = shift if ref($_[0]) eq "ARRAY";
			my $t = $params ? $type->parameterize(@$params) : $type;
			@_ && wantarray ? return($t->mouse_type, @_) : return $t->mouse_type;
		}
	}
	
	elsif ($type = $meta->get_type($sub->{sub}))
	{
		$export_coderef = _subname $type->qualified_name, sub (;@)
		{
			my $params; $params = shift if ref($_[0]) eq "ARRAY";
			my $t = $params ? $type->parameterize(@$params) : $type;
			@_ && wantarray ? return($t, @_) : return $t;
		}
	}
	
	elsif (scalar grep($_ eq $sub->{sub}, $class->_EXPORT_OK) and my $additional = $class->can($sub->{sub}))
	{
		$export_coderef = $additional;
	}
	
	else
	{
		_croak "'%s' is not exported by '%s'", $sub->{sub}, $class;
	}
	
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
	my $type = TypeTiny->check($_[0]) ? $_[0] : "Type::Tiny"->new(@_);
	my $name = $type->name;
	
	$meta->{types} ||= {};
	_croak 'type %s already exists in this library', $name if exists $meta->{types}{$name};
	_croak 'cannot add anonymous type to a library' if $type->is_anon;
	$meta->{types}{$name} = $type;
	
	no strict "refs";
	no warnings "redefine";
	
	my $class = blessed($meta);
	
	*{"$class\::$name"} = _subname $type->qualified_name, sub (;@)
	{
		my $params; $params = shift if ref($_[0]) eq "ARRAY";
		my $t = $params ? $type->parameterize(@$params) : $type;
		@_ && wantarray ? return($t, @_) : return $t;
	};
	
	*{"$class\::is_$name"} = _subname $type->qualified_name, $type->compiled_check;
	
	# There is an inlined version available, but don't use that because
	# additional coercions can be added *after* the type has been installed
	# into the library.
	#
	*{"$class\::to_$name"} = _subname $type->qualified_name, sub ($)
	{
		$type->coerce($_[0]);
	};
	
	*{"$class\::assert_$name"} = _subname $type->qualified_name, sub ($)
	{
		$type->assert_valid($_[0]);
	};
	
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

   package Types::Mine {
      use Scalar::Util qw(looks_like_number);
      use Type::Library -base;
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
      use Types::Mine qw(Number);
      has favourite_number => (is => "ro", isa => Number);
   }
   
   # Note the "-moose" flag when importing!
   package Bullwinkle {
      use Moose;
      use Types::Mine -moose, qw(Number);
      has favourite_number => (is => "ro", isa => Number);
   }
   
   # Note the "-mouse" flag when importing!
   package Maisy {
      use Mouse;
      use Types::Mine -mouse, qw(Number);
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

   Types::Mine->meta->add_type($foo);

=begin trustme

=item meta

=end trustme

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

Type libraries are exporters. For the purposes of the following examples,
assume that the C<Types::Mine> library defines types C<Number> and C<String>.

   # Exports nothing.
   # 
   use Types::Mine;
   
   # Exports a function "String" which is a constant returning
   # the String type constraint.
   #
   use Types::Mine qw( String );
   
   # Exports both String and Number as above.
   #
   use Types::Mine qw( String Number );
   
   # Same.
   #
   use Types::Mine qw( :types );
   
   # Exports a sub "is_String" so that "is_String($foo)" is equivalent
   # to "String->check($foo)".
   #
   use Types::Mine qw( is_String );
   
   # Exports "is_String" and "is_Number".
   #
   use Types::Mine qw( :is );
   
   # Exports a sub "assert_String" so that "assert_String($foo)" is
   # equivalent to "String->assert_valid($foo)".
   #
   use Types::Mine qw( assert_String );
   
   # Exports "assert_String" and "assert_Number".
   #
   use Types::Mine qw( :assert );
   
   # Exports a sub "to_String" so that "to_String($foo)" is equivalent
   # to "String->coerce($foo)".
   #
   use Types::Mine qw( to_String );
   
   # Exports "to_String" and "to_Number".
   #
   use Types::Mine qw( :to );
   
   # Exports "String", "is_String", "assert_String" and "coerce_String".
   #
   use Types::Mine qw( +String );
   
   # Exports everything.
   #
   use Types::Mine qw( :all );

Adding C<< -mouse >> or C<< -moose >> to the export list ensures that all
the type constraints exported are Mouse or Moose compatible respectively.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny::Manual>.

L<Type::Tiny>, L<Type::Utils>, L<Types::Standard>, L<Type::Coercion>.

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


