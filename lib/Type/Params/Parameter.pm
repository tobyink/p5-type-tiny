package Type::Params::Parameter;

use 5.008001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.010 ) { require Devel::TypeTiny::Perl58Compat }
}

BEGIN {
	$Type::Params::Parameter::AUTHORITY  = 'cpan:TOBYINK';
	$Type::Params::Parameter::VERSION    = '2.007_009';
}

$Type::Params::Parameter::VERSION =~ tr/_//d;

use Types::Standard qw( -is -types );

my $RE_WORDLIKE = qr/\A[^\W0-9]\w*\z/;

my $Attrs = Enum[ qw/
	name type slurpy default alias strictness coerce clone in_list optional
	getter predicate allow_dash vartail default_on_undef
	quux
/ ];

sub _croak {
	require Carp;
	Carp::croak( pop );
}

sub new {
	my $class = shift;

	my %self  = @_ == 1 ? %{$_[0]} : @_;
	$self{alias} ||= [];
	if ( defined $self{alias} and not ref $self{alias} ) {
		$self{alias} = [ $self{alias} ];
	}

	my $self = bless \%self, $class;
	
	$Attrs->all( sort keys %$self ) or do {
		require Carp;
		require Type::Utils;
		my @bad = ( ~ $Attrs )->grep( sort keys %$self );
		Carp::carp( sprintf(
			"Warning: unrecognized parameter %s: %s, continuing anyway",
			@bad == 1 ? 'option' : 'options',
			Type::Utils::english_list( @bad ),
		) );
	};

	return $self;
}

sub name       { $_[0]{name} }        sub has_name       { exists $_[0]{name} }
sub type       { $_[0]{type} }        sub has_type       { exists $_[0]{type} }
sub default    { $_[0]{default} }     sub has_default    { exists $_[0]{default} }
sub alias      { $_[0]{alias} }       sub has_alias      { @{ $_[0]{alias} } }
sub strictness { $_[0]{strictness} }  sub has_strictness { exists $_[0]{strictness} }

sub should_clone     { $_[0]{clone} }
sub default_on_undef { $_[0]{default_on_undef} }

sub in_list {
	return $_[0]{in_list} if exists $_[0]{in_list};
	$_[0]{in_list} = !$_[0]->optional;
}

sub coerce  {
	exists( $_[0]{coerce} )
		? $_[0]{coerce}
		: ( $_[0]{coerce} = $_[0]->type->has_coercion )
}

sub optional  {
	exists( $_[0]{optional} )
		? $_[0]{optional}
		: do {
			$_[0]{optional} = $_[0]->has_default || grep(
				$_->{uniq} == Optional->{uniq},
				$_[0]->type->parents,
			);
		}
}

sub getter  {
	exists( $_[0]{getter} )
		? $_[0]{getter}
		: ( $_[0]{getter} = $_[0]{name} )
}

sub predicate  {
	exists( $_[0]{predicate} )
		? $_[0]{predicate}
		: ( $_[0]{predicate} = ( $_[0]->optional ? 'has_' . $_[0]{name} : undef ) )
}

sub might_supply_new_value {
	$_[0]->has_default or $_[0]->coerce or $_[0]->should_clone;
}

sub _all_aliases {
	my ( $self, $signature ) = @_;
	my $allow_dash = $self->{allow_dash};
	$allow_dash = $signature->allow_dash if !defined $allow_dash;
	my @aliases;
	if ( $allow_dash and $self->name =~ $RE_WORDLIKE ) {
		push @aliases, sprintf( '-%s', $self->name );
	}
	for my $name ( @{ $self->alias } ) {
		push @aliases, $name;
		if ( $allow_dash and $name =~ $RE_WORDLIKE ) {
			push @aliases, sprintf( '-%s', $name );
		}
	}
	return @aliases;
}

sub _code_for_default {
	my ( $self, $signature, $coderef ) = @_;
	my $default = $self->default;

	if ( is_CodeRef $default ) {
		my $default_varname = $coderef->add_variable(
			'$default_for_' . $self->{vartail},
			\$default,
		);
		return sprintf( '%s->( %s )', $default_varname, $signature->method_invocant );
	}
	if ( is_Undef $default ) {
		return 'undef';
	}
	if ( is_Str $default ) {
		return B::perlstring( $default );
	}
	if ( is_HashRef $default ) {
		return '{}';
	}
	if ( is_ArrayRef $default ) {
		return '[]';
	}
	if ( is_ScalarRef $default ) {
		return $$default;
	}

	$self->_croak( 'Default expected to be undef, string, coderef, or empty arrayref/hashref' );
}

sub _maybe_clone {
	my ( $self, $varname ) = @_;

	if ( $self->should_clone ) {
		return sprintf( 'Storable::dclone( %s )', $varname );
	}
	return $varname;
}

sub _make_code {
	my ( $self, %args ) = ( shift, @_ );

	my $type        = $args{type} || 'arg';
	my $signature   = $args{signature};
	my $coderef     = $args{coderef};
	my $varname     = $args{input_slot};
	my $index       = $args{index};
	my $constraint  = $self->type;
	my $is_optional = $self->optional;
	my $really_optional =
		$is_optional
		&& $constraint->parent
		&& $constraint->parent->{uniq} eq Optional->{uniq}
		&& $constraint->type_parameter;

	my $strictness;
	if ( $self->has_strictness ) {
		$strictness = \ $self->strictness;
	}
	elsif ( $signature->has_strictness ) {
		$strictness = \ $signature->strictness;
	}

	my ( $vartail, $exists_check );
	if ( $args{is_named} ) {
		my $bit = $args{key};
		$bit =~ s/([_\W])/$1 eq '_' ? '__' : sprintf('_%x', ord($1))/ge;
		$vartail = $type . '_' . $bit;
		$exists_check = sprintf 'exists( %s )', $args{input_slot};
	}
	else {
		( my $input_count_varname = $args{input_var} || '' ) =~ s/\@/\$\#/;
		$vartail = $type . '_' . $index;
		$exists_check = sprintf '%s >= %d', $input_count_varname, $index;
	}

	my $block_needs_ending = 0;
	my $needs_clone = $self->should_clone;
	my $in_big_optional_block = 0;

	if ( $needs_clone and not $signature->{loaded_Storable} ) {
		$coderef->add_line( 'use Storable ();' );
		$coderef->add_gap;
		$signature->{loaded_Storable} = 1;
	}

	$coderef->add_line( sprintf(
		'# Parameter %s (type: %s)',
		$self->name || $args{input_slot},
		$constraint->display_name,
	) );

	if ( $args{is_named} and my @aliases = $self->_all_aliases($signature) ) {
		$coderef->add_line( sprintf(
			'for my $alias ( %s ) {',
			join( q{, }, map B::perlstring($_), @aliases ),
		) );
		$coderef->increase_indent;
		$coderef->add_line( 'exists $in{$alias} or next;' );
		$coderef->add_line( sprintf(
			'if ( %s ) {',
			$exists_check,
		) );
		$coderef->increase_indent;
		$coderef->add_line( sprintf(
			'%s;',
			$signature->_make_general_fail(
				coderef  => $coderef,
				message  => q{sprintf( 'Superfluous alias "%s" for argument "%s"', $alias, } . B::perlstring( $self->name || $args{input_slot} ) . q{ )},
			),
		) );
		$coderef->decrease_indent;
		$coderef->add_line( '}' );
		$coderef->add_line( 'else {' );
		$coderef->increase_indent;
		$coderef->add_line( sprintf(
			'%s = delete( $in{$alias} );',
			$varname,
		) );
		$coderef->decrease_indent;
		$coderef->add_line( '}' );
		$coderef->decrease_indent;
		$coderef->add_line( '}' );
	}

	if ( $args{is_named} and $signature->list_to_named and $self->in_list ) {
		$coderef->addf( 'if ( not exists %s ) {', $varname );
		$coderef->increase_indent;
		$coderef->addf( 'for my $ix ( 0 .. $#positional ) {' );
		$coderef->increase_indent;
		$coderef->addf( '%s or next;', ( $really_optional or $constraint )->coercibles->inline_check( '$positional[$ix]' ) );
		$coderef->addf( '( %s ) = splice( @positional, $ix, 1 );', $varname );
		$coderef->addf( 'last;' );
		$coderef->decrease_indent;
		$coderef->addf( '}' );
		$coderef->decrease_indent;
		$coderef->addf( '}' );
	}

	if ( $self->has_default ) {
		my $check = $exists_check;
		if ( $self->default_on_undef ) {
			$check = "( $check and defined $varname )";
		}
		$self->{vartail} = $vartail; # hack
		$coderef->add_line( sprintf(
			'$dtmp = %s ? %s : %s;',
			$check,
			$self->_maybe_clone( $varname ),
			$self->_code_for_default( $signature, $coderef ),
		) );
		$varname = '$dtmp';
		$needs_clone = 0;
	}
	elsif ( $self->optional ) {
		if ( $args{is_named} ) {
			$coderef->add_line( sprintf(
				'if ( %s ) {',
				$exists_check,
			) );
			$coderef->{indent} .= "\t";
			++$block_needs_ending;
			++$in_big_optional_block;
		}
		else {
			$coderef->add_line( sprintf(
				"%s\n\tor %s;",
				$exists_check,
				$signature->_make_return_expression( is_early => 1 ),
			) );
		}
	}
	elsif ( $args{is_named} ) {
		$coderef->add_line( sprintf(
			"%s\n\tor %s;",
			$exists_check,
			$signature->_make_general_fail(
				coderef => $coderef,
				message => "'Missing required parameter: $args{key}'",
			),
		) );
	}

	if ( $needs_clone ) {
		$coderef->add_line( sprintf(
			'$dtmp = %s;',
			$self->_maybe_clone( $varname ),
		) );
		$varname = '$dtmp';
		$needs_clone = 0;
	}

	if ( $constraint->has_coercion and $constraint->coercion->can_be_inlined ) {
		$coderef->add_line( sprintf(
			'$tmp%s = %s;',
			( $is_optional ? '{x}' : '' ),
			$constraint->coercion->inline_coercion( $varname )
		) );
		$varname = '$tmp' . ( $is_optional ? '{x}' : '' );
	}
	elsif ( $constraint->has_coercion ) {
		my $coercion_varname = $coderef->add_variable(
			'$coercion_for_' . $vartail,
			\ $constraint->coercion->compiled_coercion,
		);
		$coderef->add_line( sprintf(
			'$tmp%s = &%s( %s );',
			( $is_optional ? '{x}' : '' ),
			$coercion_varname,
			$varname,
		) );
		$varname = '$tmp' . ( $is_optional ? '{x}' : '' );
	}

	undef $Type::Tiny::ALL_TYPES{ $constraint->{uniq} };
	$Type::Tiny::ALL_TYPES{ $constraint->{uniq} } = $constraint;

	my $strictness_test = '';
	if ( $strictness and $$strictness eq 1 ) {
		$strictness_test = '';
	}
	elsif ( $strictness and $$strictness ) {
		$strictness_test = sprintf "( not %s )\n\tor ", $$strictness;
	}

	if ( $strictness and not $$strictness ) {
		$coderef->add_line( '1; # ... nothing to do' );
	}
	elsif ( $constraint->{uniq} == Any->{uniq} ) {
		$coderef->add_line( '1; # ... nothing to do' );
	}
	elsif ( $constraint->can_be_inlined ) {
		$coderef->add_line( $strictness_test . sprintf(
			"%s\n\tor %s;",
			( $really_optional or $constraint )->inline_check( $varname ),
			$signature->_make_constraint_fail(
				coderef      => $coderef,
				parameter    => $self,
				constraint   => $constraint,
				varname      => $varname,
				display_var  => $args{display_var},
			),
		) );
	}
	else {
		my $compiled_check_varname = $coderef->add_variable(
			'$check_for_' . $vartail,
			\ ( ( $really_optional or $constraint )->compiled_check ),
		);
		$coderef->add_line( $strictness_test . sprintf(
			"&%s( %s )\n\tor %s;",
			$compiled_check_varname,
			$varname,
			$signature->_make_constraint_fail(
				coderef      => $coderef,
				parameter    => $self,
				constraint   => $constraint,
				varname      => $varname,
				display_var  => $args{display_var},
			),
		) );
	}

	if ( $args{output_var} ) {
		$coderef->add_line( sprintf(
			'push( %s, %s );',
			$args{output_var},
			$varname,
		) );
	}
	elsif ( $args{output_slot} and $args{output_slot} ne $varname ) {
		if ( !$in_big_optional_block and $varname =~ /\{/ ) {
			$coderef->add_line( sprintf(
				'%s = %s if exists( %s );',
				$args{output_slot},
				$varname,
				$varname,
			) );
		}
		else {
			$coderef->add_line( sprintf(
				'%s = %s;',
				$args{output_slot},
				$varname,
			) );
		}
	}

	if ( $args{is_named} ) {
		$coderef->add_line( sprintf(
			'delete( %s );',
			$args{input_slot},
		) );
	}

	if ( $block_needs_ending ) {
		$coderef->{indent} =~ s/\s$//;
		$coderef->add_line( '}' );
	}

	$coderef->add_gap;

	$self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Params::Parameter - internal representation of a parameter in a function signature

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can be used to provide basic introspection
for signatures.

=head2 Constructor

=over

=item C<< new(%attributes) >>

=back

=head2 Attributes

All attributes are read-only.

=over

=item C<< type >> B<TypeTiny>

Type constraint for the parameter.

=item C<< default >> B<< CodeRef|ScalarRef|Ref|Str|Undef >>

A default for the parameter: either a coderef to generate a value,
a reference to a string of Perl code to generate the value, an
a reference to an empty array or empty hash, a literal string
to use as a default, or a literal undef to use as a default.

=item C<< strictness >> B<< Bool|ScalarRef >>

A boolean indicating whether to be stricter with type checks,
or a reference to a string of Perl code naming a Perl variable
or constant which controls strict behaviour.

=item C<< clone >> B<< Bool >>

The method for accessing this is called C<should_clone> for no
particular reason.

=item C<< coerce >> B<< Bool >>

Defaults to true if C<type> has a coercion.

=item C<< optional >> B<< Bool >>

Defaults to true if there is a C<default> or if C<type> is a subtype of
B<Optional>.

=item C<< in_list >> B<< Bool >>

Boolean that is only used when the signature has the C<list_to_named>
feature enabled.

=item C<< default_on_undef >> B<< Bool >>

Should the default be triggered if the caller passes an explicit undef?

=back

=head3 Attributes related to named parameters

=over

=item C<< name >> B<Str>

=item C<< alias >> B<< ArrayRef[Str] >>

=item C<< getter >> B<Str>

=item C<< predicate >> B<< Str >>

=back

=head2 Methods

=head3 Predicates

Predicate methods return true/false to indicate the presence or absence of
attributes.

=over

=item C<< has_type >>

=item C<< has_default >>

=item C<< has_strictness >>

=item C<< has_name >>

=item C<< has_alias >>

=back

=head3 Other methods

=over

=item C<< might_supply_new_value >>

Indicates that the parameter can't simply be referenced within C<< @_ >>
because a default value might be used, the given value might be coerced,
or the given value might be cloned using L<Storable>.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Type::Params>, L<Type::Params::Signature>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
