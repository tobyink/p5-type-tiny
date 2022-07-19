package Type::Params::Parameter;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.008 ) { require Devel::TypeTiny::Perl56Compat }
	if ( $] < 5.010 ) { require Devel::TypeTiny::Perl58Compat }
}

BEGIN {
	$Type::Params::Parameter::AUTHORITY  = 'cpan:TOBYINK';
	$Type::Params::Parameter::VERSION    = '1.016002';
}

$Type::Params::Parameter::VERSION =~ tr/_//d;

use Types::Standard qw( -is -types );

sub _croak {
	require Carp;
	Carp::croak( pop );
}

sub new {
	my $class = shift;

	my %self  = @_ == 1 ? %{$_[0]} : @_;

	bless \%self, $class;
}

sub name      { $_[0]{name} }       sub has_name      { exists $_[0]{name} }
sub type      { $_[0]{type} }       sub has_type      { exists $_[0]{type} }
sub default   { $_[0]{default} }    sub has_default   { exists $_[0]{default} }

sub should_clone { $_[0]{clone} }

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

sub _code_for_default {
	my $self = shift;
	my $default = $self->default;

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

	if ( $self->has_default and is_CodeRef $self->default ) {
		my $default_varname = $coderef->add_variable(
			'$default_for_' . $vartail,
			\ $self->default,
		);
		$coderef->add_line( sprintf(
			'$dtmp = %s ? %s : &%s;',
			$exists_check,
			$self->_maybe_clone( $varname ),
			$default_varname,
		) );
		$varname = '$dtmp';
		$needs_clone = 0;
	}
	elsif ( $self->has_default ) {
		$coderef->add_line( sprintf(
			'$dtmp = %s ? %s : %s;',
			$exists_check,
			$self->_maybe_clone( $varname ),
			$self->_code_for_default,
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

	if ( $constraint->{uniq} == Any->{uniq} ) {
		$coderef->add_line( '1; # ... nothing to do' );
	}
	elsif ( $constraint->can_be_inlined ) {
		$coderef->add_line( sprintf(
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
		$coderef->add_line( sprintf(
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
		if ( $varname =~ /\{/ ) {
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
