use 5.008001;
use strict;
use warnings;

use Carp ();
use Exporter::Tiny ();
use Scalar::Util ();
use Tie::Array ();
use Tie::Hash ();
use Tie::Scalar ();

++$Carp::CarpInternal{"Type::Tie::$_"} for qw( BASE SCALAR ARRAY HASH );

{
	package Type::Tie;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.999_011';
	our @ISA       = qw( Exporter::Tiny );
	our @EXPORT    = qw( ttie );
	
	$VERSION =~ tr/_//d;
	
	sub ttie (\[$@%]@)#>&%*/&<%\$[]^!@;@)
	{
		my ($ref, $type, @vals) = @_;
		
		if ( 'HASH' eq ref $ref ) {
			tie %$ref, "Type::Tie::HASH", $type;
			%$ref = @vals if @vals;
		}
		elsif ( 'ARRAY' eq ref $ref ) {
			tie @$ref, "Type::Tie::ARRAY", $type;
			@$ref = @vals if @vals;
		}
		else {
			tie $$ref, "Type::Tie::SCALAR", $type;
			$$ref = $vals[-1] if @vals;
		}
		return $ref;
	}
};

{
	package Type::Tie::BASE;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.999_011';
	
	$VERSION =~ tr/_//d;
	
	BEGIN {
		my $impl;
		$impl ||= eval { require Hash::FieldHash;               'Hash::FieldHash' };
		$impl ||= eval { require Hash::Util::FieldHash;         'Hash::Util::FieldHash' };
		$impl ||= do   { require Hash::Util::FieldHash::Compat; 'Hash::Util::FieldHash::Compat' };
		$impl->import('fieldhash');
	};
	
	fieldhash(my %TYPE);
	fieldhash(my %COERCE);
	fieldhash(my %CHECK);
	
	sub _set_type {
		my $self = shift;
		my $type = $_[0];
		
		$TYPE{$self} = $type;
		
		if ( Scalar::Util::blessed($type) and $type->isa( 'Type::Tiny' ) ) {
			$CHECK{$self} = $type->compiled_check;
			$COERCE{$self} = undef;
			$COERCE{$self} = $type->coercion->compiled_coercion
				if $type->has_coercion;
		}
		else {
			$CHECK{$self} = $type->can('compiled_check')
				? $type->compiled_check
				: sub { $type->check($_[0]) };
			$COERCE{$self} = undef;
			$COERCE{$self} = sub { $type->coerce($_[0]) }
				if $type->can("has_coercion")
				&& $type->can("coerce")
				&& $type->has_coercion;
		}
	}
	
	sub type {
		my $self = shift;
		$TYPE{$self};
	}
	
	sub _dd {
		require Type::Tiny;
		goto \&Type::Tiny::_dd;
	}
	
	sub coerce_and_check_value {
		my $self   = shift;
		my $check  = $CHECK{$self};
		my $coerce = $COERCE{$self};
		
		my @vals = map {
			my $val = $coerce ? $coerce->($_) : $_;
			if (not $check->($val)) {
				my $type = $TYPE{$self};
				Carp::croak(
					$type && $type->can('get_message')
						? $type->get_message($val)
						: sprintf("%s does not meet type constraint %s", _dd($_), $type||'Unknown')
				);
			}
			$val;
		} ( my @cp = @_ );  # need to copy @_ for Perl < 5.14
		
		wantarray ? @vals : $vals[0];
	}
	
	# store the $type for the exiting instances so the type can be set
	# (uncloned) in the clone too. A clone process could be cloning several
	# instances of this class, so use a hash to hold the types during
	# cloning. These types are reference counted, so the last reference to
	# a particular type deletes its key.
	my %tmp_clone_types;
	sub STORABLE_freeze {
		die "Scalar::Util is needed for cloning with Storage::dclone"
			unless eval { require Scalar::Util };
		my $self = shift;
		my $cloning = shift;
		
		die "Storage::freeze only supported for dclone-ing"
			unless $cloning;
		
		my $type = $TYPE{$self};
		my $refaddr = Scalar::Util::refaddr($type);
		$tmp_clone_types{$refaddr} ||= [ $type, 0 ];
		++$tmp_clone_types{$refaddr}[1];
		return (pack('j', $refaddr), $self);
	}
	
	sub STORABLE_thaw {
		my $self = shift;
		my $cloning = shift;
		my $packedRefaddr = shift;
		my $obj = shift;
		
		die "Storage::thaw only supported for dclone-ing"
			unless $cloning;
		
		$self->_STORABLE_thaw_update_from_obj($obj);
		my $refaddr = unpack('j', $packedRefaddr);
		my $type = $tmp_clone_types{$refaddr}[0];
		--$tmp_clone_types{$refaddr}[1]
			or delete $tmp_clone_types{$refaddr};
		$self->_set_type($type);
	}
};

{
	package Type::Tie::ARRAY;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.999_011';
	our @ISA       = qw( Tie::StdArray Type::Tie::BASE );
	
	$VERSION =~ tr/_//d;
	
	sub TIEARRAY {
		my $class = shift;
		my $self = $class->SUPER::TIEARRAY;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE {
		my $self = shift;
		$self->SUPER::STORE($_[0], $self->coerce_and_check_value($_[1]));
	}
	
	sub PUSH {
		my $self = shift;
		$self->SUPER::PUSH( $self->coerce_and_check_value(@_) );
	}
	
	sub UNSHIFT {
		my $self = shift;
		$self->SUPER::UNSHIFT( $self->coerce_and_check_value(@_) );
	}
	
	sub SPLICE {
		my $self = shift;
		my ($start, $len, @rest) = @_;
		$self->SUPER::SPLICE($start, $len, $self->coerce_and_check_value(@rest) );
	}
	
	sub _STORABLE_thaw_update_from_obj {
		my $self = shift;
		my $obj = shift;
		@$self = @$obj;
	}
};

{
	package Type::Tie::HASH;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.999_011';
	our @ISA       = qw( Tie::StdHash Type::Tie::BASE );
	
	$VERSION =~ tr/_//d;
	
	sub TIEHASH {
		my $class = shift;
		my $self = $class->SUPER::TIEHASH;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE {
		my $self = shift;
		$self->SUPER::STORE($_[0], $self->coerce_and_check_value($_[1]));
	}
	
	sub _STORABLE_thaw_update_from_obj {
		my $self = shift;
		my $obj = shift;
		%$self = %$obj;
	}
};

{
	package Type::Tie::SCALAR;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '1.999_011';
	our @ISA       = qw( Tie::StdScalar Type::Tie::BASE );
	
	$VERSION =~ tr/_//d;
	
	sub TIESCALAR {
		my $class = shift;
		my $self = $class->SUPER::TIESCALAR;
		$self->_set_type($_[0]);
		return $self;
	}
	
	sub STORE {
		my $self = shift;
		$self->SUPER::STORE( $self->coerce_and_check_value($_[0]) );
	}
	
	sub _STORABLE_thaw_update_from_obj {
		my $self = shift;
		my $obj = shift;
		$self = $obj;
	}
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tie - tie a variable to a type constraint

=head1 SYNOPSIS

Type::Tie is a response to this sort of problem...

   use strict;
   use warnings;
   
   {
      package Local::Testing;
      use Moose;
      has numbers => ( is => "ro", isa => "ArrayRef[Num]" );
   }
   
   # Nice list of numbers.
   my @N = ( 1, 2, 3, 3.14159 );
   
   # Create an object with a reference to that list.
   my $object = Local::Testing->new(numbers => \@N);
   
   # Everything OK so far...
   
   # Now watch this!
   push @N, "Monkey!";
   print $object->dump;
   
   # Houston, we have a problem!

Just declare C<< @N >> like this:

   use Type::Tie;
   use Types::Standard qw( Num );
   
   ttie my @N, Num, ( 1, 2, 3, 3.14159 );

Now any attempt to add a non-numeric value to C<< @N >> will die.

=head1 DESCRIPTION

This module exports a single function: C<ttie>. C<ttie> ties a variable
to a type constraint, ensuring that whatever values stored in the variable
will conform to the type constraint. If the type constraint has coercions,
these will be used if necessary to ensure values assigned to the variable
conform.

   use Type::Tie;
   use Types::Standard qw( Int Num );
   
   ttie my $count, Int->plus_coercions(Num, 'int $_'), 0;
   
   print tied($count)->type, "\n";   # 'Int'
   
   $count++;            # ok
   $count = 2;          # ok
   $count = 3.14159;    # ok, coerced to 3
   $count = "Monkey!";  # dies

While the examples in documentation (and the test suite) show type
constraints from L<Types::Standard>, any type constraint objects
supporting the L<Type::API> interfaces should work. This includes:

=over

=item *

L<Moose::Meta::TypeConstraint> / L<MooseX::Types>

=item *

L<Mouse::Meta::TypeConstraint> / L<MouseX::Types>

=item *

L<Specio>

=item *

L<Type::Tiny|Type::Tiny::Manual>

=back

However, with Type::Tiny, you don't even need to C<< use Type::Tie >>.

   use Types::Standard qw( Int Num );
   
   tie my $count, Int->plus_coercions(Num, 'int $_'), 0;
   
   print tied($count)->type, "\n";   # 'Int'
   
   $count++;            # ok
   $count = 2;          # ok
   $count = 3.14159;    # ok, coerced to 3
   $count = "Monkey!";  # dies

=head2 Cloning tied variables

If you clone tied variables with C<dclone> from L<Storable>, the clone
will also be tied. Other cloning mechanisms like the L<Clone> module
are not currently supported, and just produce clones without the tie.

=begin trustme

=item ttie

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::API>,
L<Type::Tiny>,
L<Type::Utils>,
L<Moose::Manual::Types>,
L<MooseX::Lexical::Types>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2018-2019, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

