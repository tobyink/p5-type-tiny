package Type::Params::Signature;

use 5.008001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.010 ) { require Devel::TypeTiny::Perl58Compat }
}

BEGIN {
	$Type::Params::Signature::AUTHORITY  = 'cpan:TOBYINK';
	$Type::Params::Signature::VERSION    = '2.008006';
}

$Type::Params::Signature::VERSION =~ tr/_//d;

use B ();
use Eval::TypeTiny::CodeAccumulator;
use Types::Standard qw( -is -types -assert );
use Types::TypeTiny qw( -is -types to_TypeTiny );
use Type::Params::Parameter;

my $Attrs = Enum[ qw/
	caller_level package subname description _is_signature_for ID
	method head tail parameters slurpy
	message on_die next fallback strictness is_named allow_dash method_invocant
	bless class constructor named_to_list list_to_named oo_trace
	class_prefix class_attributes
	returns_scalar returns_list
	want_details want_object want_source can_shortcut coderef
	quux mite_signature is_wrapper
/ ]; # quux for reasons

sub _croak {
	require Error::TypeTiny;
	return Error::TypeTiny::croak( pop );
}

sub _new_parameter {
	shift;
	'Type::Params::Parameter'->new( @_ );
}

sub _new_code_accumulator {
	shift;
	'Eval::TypeTiny::CodeAccumulator'->new( @_ );
}

sub new {
	my $class = shift;
	my %self = @_ == 1 ? %{$_[0]} : @_;
	my $self = bless \%self, $class;
	$self->{parameters}   ||= [];
	$self->{class_prefix} ||= 'Type::Params::OO::Klass';
	$self->{next}         ||= delete $self->{goto_next} if exists $self->{goto_next};
	$self->BUILD;
	$Attrs->all( sort keys %$self ) or do {
		require Carp;
		require Type::Utils;
		my @bad = ( ~ $Attrs )->grep( sort keys %$self );
		Carp::carp( sprintf(
			"Warning: unrecognized signature %s: %s, continuing anyway",
			@bad == 1 ? 'option' : 'options',
			Type::Utils::english_list( @bad ),
		) );
	};
	return $self;
}

{
	my $klass_id;
	my %klass_cache;
	sub BUILD {
		my $self = shift;

		if ( $self->{named_to_list} and not is_ArrayRef $self->{named_to_list} ) {
			$self->{named_to_list} = [ map $_->name, @{ $self->{parameters} } ];
		}

		if ( delete $self->{rationalize_slurpies} ) {
			$self->_rationalize_slurpies;
		}

		if ( $self->{method} ) {
			my $type = $self->{method};
			$type =
				is_Int($type) ? Defined :
				is_Str($type) ? do { require Type::Utils; Type::Utils::dwim_type( $type, $self->{package} ? ( for => $self->{package} ) : () ) } :
				to_TypeTiny( $type );
			unshift @{ $self->{head} ||= [] }, $self->_new_parameter(
				name    => 'invocant',
				type    => $type,
			);
		}

		$self->_rationalize_returns;

		if ( defined $self->{bless} and is_BoolLike $self->{bless} and $self->{bless} and not $self->{named_to_list} ) {
			my $klass_key     = $self->_klass_key;
			$self->{bless}    = ( $klass_cache{$klass_key} ||= sprintf( '%s%d', $self->{class_prefix}, ++$klass_id ) );
			$self->{oo_trace} = 1 unless exists $self->{oo_trace};
			$self->make_class;
		}
		if ( is_ArrayRef $self->{class} ) {
			$self->{constructor} = $self->{class}->[1];
			$self->{class}       = $self->{class}->[0];
		}
	}
}

sub _klass_key {
	my $self = shift;

	my @parameters = @{ $self->parameters };
	if ( $self->has_slurpy ) {
		push @parameters, $self->slurpy;
	}

	no warnings 'uninitialized';
	join(
		'|',
		map sprintf( '%s*%s*%s', $_->name, $_->getter, $_->predicate ),
		sort { $a->{name} cmp $b->{name} } @parameters
	);
}

sub _rationalize_slurpies {
	my $self = shift;

	my $parameters = $self->parameters;

	if ( $self->is_named ) {
		my ( @slurpy, @rest );

		for my $parameter ( @$parameters ) {
			if ( $parameter->type->is_strictly_a_type_of( Slurpy ) ) {
				push @slurpy, $parameter;
			}
			elsif ( $parameter->{slurpy} ) {
				$parameter->{type} = Slurpy[ $parameter->type ];
				push @slurpy, $parameter;
			}
			else {
				push @rest, $parameter;
			}
		}

		if ( @slurpy == 1 ) {
			my $constraint = $slurpy[0]->type;
			if ( $constraint->type_parameter && $constraint->type_parameter->{uniq} == Any->{uniq} or $constraint->my_slurp_into eq 'HASH' ) {
				$self->{slurpy} = $slurpy[0];
				@$parameters = @rest;
			}
			else {
				$self->_croak( 'Signatures with named parameters can only have slurpy parameters which are a subtype of HashRef' );
			}
		}
		elsif ( @slurpy ) {
			$self->_croak( 'Found multiple slurpy parameters! There can be only one' );
		}
	}
	elsif ( @$parameters ) {
		if ( $parameters->[-1]->type->is_strictly_a_type_of( Slurpy ) ) {
			$self->{slurpy} = pop @$parameters;
		}
		elsif ( $parameters->[-1]{slurpy} ) {
			$self->{slurpy} = pop @$parameters;
			$self->{slurpy}{type} = Slurpy[ $self->{slurpy}{type} ];
		}

		for my $parameter ( @$parameters ) {
			if ( $parameter->type->is_strictly_a_type_of( Slurpy ) or $parameter->{slurpy} ) {
				$self->_croak( 'Parameter following slurpy parameter' );
			}
		}
	}

	if ( $self->{slurpy} and $self->{slurpy}->has_default ) {
		require Carp;
		our @CARP_NOT = ( __PACKAGE__, 'Type::Params' );
		Carp::carp( "Warning: the default for the slurpy parameter will be ignored, continuing anyway" );
		delete $self->{slurpy}{default};
	}
	
	if ( $self->{slurpy} and $self->{slurpy}->optional ) {
		require Carp;
		our @CARP_NOT = ( __PACKAGE__, 'Type::Params' );
		Carp::carp( "Warning: the optional for the slurpy parameter will be ignored, continuing anyway" );
		delete $self->{slurpy}{optional};
	}
}

sub _rationalize_returns {
	my $self = shift;
	
	my $typify = sub {
		my $ref = shift;
		if ( is_Str $$ref ) {
			require Type::Utils;
			$$ref = Type::Utils::dwim_type( $$ref, $self->{package} ? ( for => $self->{package} ) : () );
		}
		else {
			$$ref = to_TypeTiny( $$ref );
		}
	};
	
	if ( my $r = delete $self->{returns} ) {
		$typify->( \ $r );
		$self->{returns_scalar} ||= $r;
		$self->{returns_list}   ||= ArrayRef->of( $r );
	}

	exists $self->{$_} && $typify->( \ $self->{$_} )
		for qw/ returns_scalar returns_list /;
	
	return $self;
}

sub _parameters_from_list {
	my ( $class, $style, $list, %opts ) = @_;
	my @return;
	my $is_named = ( $style eq 'named' );

	while ( @$list ) {
		my ( $type, %param_opts );
		if ( $is_named ) {
			$param_opts{name} = assert_Str( shift( @$list ) );
		}
		if ( is_HashRef $list->[0] and exists $list->[0]{slurpy} and not is_Bool $list->[0]{slurpy} ) {
			my %new_opts = %{ shift( @$list ) };
			$type = delete $new_opts{slurpy};
			%param_opts = ( %param_opts, %new_opts, slurpy => 1 );
		}
		else {
			$type = shift( @$list );
		}
		if ( is_HashRef( $list->[0] ) ) {
			unless ( exists $list->[0]{slurpy} and not is_Bool $list->[0]{slurpy} ) {
				%param_opts = ( %param_opts, %{ +shift( @$list ) } );
			}
		}
		$param_opts{type} =
			is_Int($type) ? ( $type ? Any : do { $param_opts{optional} = !!1; Any; } ) :
			is_Str($type) ? do { require Type::Utils; Type::Utils::dwim_type( $type, $opts{package} ? ( for => $opts{package} ) : () ) } :
			to_TypeTiny( $type );
		my $parameter = $class->_new_parameter( %param_opts );
		push @return, $parameter;
	}

	return \@return;
}

sub new_from_compile {
	my $class = shift;
	my $style = shift;
	my $is_named = ( $style eq 'named' );

	my %opts  = ();
	while ( is_HashRef $_[0] and not exists $_[0]{slurpy} ) {
		%opts = ( %opts, %{ +shift } );
	}

	for my $pos ( qw/ head tail / ) {
		next unless defined $opts{$pos};
		if ( is_Int( $opts{$pos} ) ) {
			$opts{$pos} = [ ( Any ) x $opts{$pos} ];
		}
		$opts{$pos} = $class->_parameters_from_list( positional => $opts{$pos}, %opts );
	}

	my $list = [ @_ ];
	$opts{is_named}   = $is_named;
	$opts{parameters} = $class->_parameters_from_list( $style => $list, %opts );

	my $self = $class->new( %opts, rationalize_slurpies => 1 );
	return $self;
}

sub new_from_v2api {
	my ( $class, $opts ) = @_;

	my $positional = delete( $opts->{positional} ) || delete( $opts->{pos} );
	my $named      = delete( $opts->{named} );
	my $multiple   = delete( $opts->{multiple} ) || delete( $opts->{multi} );

	$class->_croak( "Signature must be positional, named, or multiple" )
		unless $positional || $named || $multiple;

	if ( $multiple ) {
		if ( is_HashRef $multiple ) {
			my @tmp;
			while ( my ( $name, $alt ) = each %$multiple ) {
				push @tmp,
					is_HashRef($alt)  ? { ID => $name, %$alt } :
					is_ArrayRef($alt) ? { ID => $name, pos => $alt } :
					is_CodeRef($alt)  ? { ID => $name, closure => $alt } :
					$class->_croak( "Bad alternative in multiple signature" );
			}
			$multiple = \@tmp;
		}
		elsif ( not is_ArrayRef $multiple ) {
			$multiple = [];
		}
		unshift @$multiple, { positional => $positional } if $positional;
		unshift @$multiple, { named      => $named      } if $named;
		require Type::Params::Alternatives;
		return 'Type::Params::Alternatives'->new(
			base_options => $opts,
			alternatives => $multiple,
			sig_class    => $class,
		);
	}

	my ( $sig_kind, $args ) = ( pos => $positional );
	if ( $named ) {
		$opts->{bless} = 1 unless exists $opts->{bless};
		( $sig_kind, $args ) = ( named => $named );
		$class->_croak( "Signature cannot have both positional and named arguments" )
			if $positional;
	}

	return $class->new_from_compile( $sig_kind, $opts, @$args );
}

sub package       { $_[0]{package} }
sub subname       { $_[0]{subname} }
sub description   { $_[0]{description} }     sub has_description   { exists $_[0]{description} }
sub method        { $_[0]{method} }
sub head          { $_[0]{head} }            sub has_head          { exists $_[0]{head} }
sub tail          { $_[0]{tail} }            sub has_tail          { exists $_[0]{tail} }
sub parameters    { $_[0]{parameters} }      sub has_parameters    { exists $_[0]{parameters} }
sub slurpy        { $_[0]{slurpy} }          sub has_slurpy        { exists $_[0]{slurpy} }
sub on_die        { $_[0]{on_die} }          sub has_on_die        { exists $_[0]{on_die} }
sub strictness    { $_[0]{strictness} }      sub has_strictness    { exists $_[0]{strictness} }
sub next          { $_[0]{next} }
sub goto_next     { $_[0]{next} }
sub is_named      { $_[0]{is_named} }
sub allow_dash    { $_[0]{allow_dash} }
sub bless         { $_[0]{bless} }
sub class         { $_[0]{class} }
sub constructor   { $_[0]{constructor} }
sub named_to_list { $_[0]{named_to_list} }
sub list_to_named { $_[0]{list_to_named} }
sub oo_trace      { $_[0]{oo_trace} }
sub returns_scalar{ $_[0]{returns_scalar} }  sub has_returns_scalar{ defined $_[0]{returns_scalar} }
sub returns_list  { $_[0]{returns_list} }    sub has_returns_list  { defined $_[0]{returns_list} }

sub method_invocant { $_[0]{method_invocant} = defined( $_[0]{method_invocant} ) ? $_[0]{method_invocant} : 'undef' }

sub can_shortcut {
	return $_[0]{can_shortcut}
		if exists $_[0]{can_shortcut};
	$_[0]{can_shortcut} = !(
		$_[0]->slurpy or
		grep $_->might_supply_new_value, @{ $_[0]->parameters }
	);
}

sub coderef {
	$_[0]{coderef} ||= $_[0]->_build_coderef;
}

sub _build_coderef {
	my $self = shift;
	my $coderef = $self->_new_code_accumulator(
		description => $self->description
			|| sprintf( q{parameter validation for '%s::%s'}, $self->package || '', $self->subname || '__ANON__' )
	);

	$self->_coderef_start( $coderef );
	$self->_coderef_head( $coderef ) if $self->has_head;
	$self->_coderef_tail( $coderef ) if $self->has_tail;
	$self->_coderef_parameters( $coderef );
	if ( $self->has_slurpy ) {
		$self->_coderef_slurpy( $coderef );
	}
	elsif ( $self->is_named ) {
		$self->_coderef_extra_names( $coderef );
	}
	$self->_coderef_end( $coderef );

	return $coderef;
}

sub _coderef_start {
	my ( $self, $coderef ) = ( shift, @_ );

	$coderef->add_line( 'sub {' );
	$coderef->{indent} .= "\t";

	if ( my $next = $self->next ) {
		if ( is_CodeLike $next ) {
			$coderef->add_variable( '$__NEXT__', \$next );
		}
		else {
			$coderef->add_line( 'my $__NEXT__ = shift;' );
			$coderef->add_gap;
		}
	}

	if ( $self->method ) {
		# Passed to parameter defaults
		$self->{method_invocant} = '$__INVOCANT__';
		$coderef->add_line( sprintf 'my %s = $_[0];', $self->method_invocant );
		$coderef->add_gap;
	}

	$self->_coderef_start_extra( $coderef );

	my $extravars = '';
	if ( $self->has_head ) {
		$extravars .= ', @head';
	}
	if ( $self->has_tail ) {
		$extravars .= ', @tail';
	}

	if ( $self->is_named ) {
		$coderef->add_line( "my ( \%out, \%in, \%tmp, \$tmp, \$dtmp$extravars );" );
	}
	elsif ( $self->can_shortcut ) {
		$coderef->add_line( "my ( \%tmp, \$tmp$extravars );" );
	}
	else {
		$coderef->add_line( "my ( \@out, \%tmp, \$tmp, \$dtmp$extravars );" );
	}

	if ( $self->has_on_die ) {
		$coderef->add_variable( '$__ON_DIE__', \ $self->on_die );
	}

	$coderef->add_gap;

	$self->_coderef_check_count( $coderef );

	$coderef->add_gap;

	$self;
}

sub _coderef_start_extra {}

sub _coderef_check_count {
	my ( $self, $coderef ) = ( shift, @_ );

	my $strictness_test = '';
	if ( defined $self->strictness and $self->strictness eq 1 ) {
		$strictness_test = '';
	}
	elsif ( $self->strictness ) {
		$strictness_test = sprintf '( not %s ) or ', $self->strictness;
	}
	elsif ( $self->has_strictness ) {
		return $self;
	}

	my $headtail = 0;
	$headtail += @{ $self->head } if $self->has_head;
	$headtail += @{ $self->tail } if $self->has_tail;

	my $is_named = $self->is_named;
	my $min_args = 0;
	my $max_args = 0;
	my $seen_optional = 0;
	for my $parameter ( @{ $self->parameters } ) {
		if ( $parameter->optional ) {
			++$seen_optional;
			++$max_args;
		}
		else {
			$seen_optional and !$is_named and $self->_croak(
				'Non-Optional parameter following Optional parameter',
			);
			++$max_args;
			++$min_args;
		}
	}

	undef $max_args if $self->has_slurpy;

	# Note: code related to $max_args_if_hash is currently commented out
	# because it handles this badly:
	#
	#   my %opts = ( x => 1, y => 1 );
	#   your_func( %opts, y => 2 ); # override y
	#

	if ( $is_named and $self->list_to_named ) {
		require List::Util;
		my $args_if_hashref  = $headtail + 1;
		my $min_args_if_list = $headtail + List::Util::sum( 0, map { $_->optional ? 0 : $_->in_list ? 1 : 2 } @{ $self->parameters } );
		$self->{min_args} = List::Util::min( $args_if_hashref, $min_args_if_list );
		
		$coderef->add_line( $strictness_test . sprintf(
			"\@_ >= %d\n\tor %s;",
			$self->{min_args},
			$self->_make_count_fail(
				coderef   => $coderef,
				got       => 'scalar( @_ )',
			),
		) );
	}
	elsif ( $is_named ) {
		my $args_if_hashref  = $headtail + 1;
		my $hashref_index    = @{ $self->head || [] };
		my $arity_if_hash    = $headtail % 2;
		my $min_args_if_hash = $headtail + ( 2 * $min_args );
		#my $max_args_if_hash = defined( $max_args )
		#	? ( $headtail + ( 2 * $max_args ) )
		#	: undef;

		require List::Util;
		$self->{min_args} = List::Util::min( $args_if_hashref, $min_args_if_hash );
		#if ( defined $max_args_if_hash ) {
		#	$self->{max_args} = List::Util::max( $args_if_hashref, $max_args_if_hash );
		#}

		my $extra_conditions = '';
		#if ( defined $max_args_if_hash and $min_args_if_hash==$max_args_if_hash ) {
		#	$extra_conditions .= " && \@_ == $min_args_if_hash"
		#}
		#else {
			$extra_conditions .= " && \@_ >= $min_args_if_hash"
				if $min_args_if_hash;
		#	$extra_conditions .= " && \@_ <= $max_args_if_hash"
		#		if defined $max_args_if_hash;
		#}

		$coderef->add_line( $strictness_test . sprintf(
			"\@_ == %d && %s\n\tor \@_ %% 2 == %d%s\n\tor %s;",
			$args_if_hashref,
			HashRef->inline_check( sprintf '$_[%d]', $hashref_index ),
			$arity_if_hash,
			$extra_conditions,
			$self->_make_count_fail(
				coderef   => $coderef,
				got       => 'scalar( @_ )',
			),
		) );
	}
	else {
		$min_args += $headtail;
		$max_args += $headtail if defined $max_args;

		$self->{min_args} = $min_args;
		$self->{max_args} = $max_args;

		if ( defined $max_args and $min_args == $max_args ) {
			$coderef->add_line( $strictness_test . sprintf(
				"\@_ == %d\n\tor %s;",
				$min_args,
				$self->_make_count_fail(
					coderef   => $coderef,
					minimum   => $min_args,
					maximum   => $max_args,
					got       => 'scalar( @_ )',
				),
			) );
		}
		elsif ( $min_args and defined $max_args ) {
			$coderef->add_line( $strictness_test . sprintf(
				"\@_ >= %d && \@_ <= %d\n\tor %s;",
				$min_args,
				$max_args,
				$self->_make_count_fail(
					coderef   => $coderef,
					minimum   => $min_args,
					maximum   => $max_args,
					got       => 'scalar( @_ )',
				),
			) );
		}
		else {
			$coderef->add_line( $strictness_test . sprintf(
				"\@_ >= %d\n\tor %s;",
				$min_args || 0,
				$self->_make_count_fail(
					coderef   => $coderef,
					minimum   => $min_args || 0,
					got       => 'scalar( @_ )',
				),
			) );
		}
	}
}

sub _coderef_head {
	my ( $self, $coderef ) = ( shift, @_ );
	$self->has_head or return;

	my $size = @{ $self->head };
	$coderef->add_line( sprintf(
		'@head = splice( @_, 0, %d );',
		$size,
	) );

	$coderef->add_gap;

	my $i = 0;
	for my $parameter ( @{ $self->head } ) {
		$parameter->_make_code(
			signature   => $self,
			coderef     => $coderef,
			input_slot  => sprintf( '$head[%d]', $i ),
			input_var   => '@head',
			output_slot => sprintf( '$head[%d]', $i ),
			output_var  => undef,
			index       => $i,
			type        => 'head',
			display_var => sprintf( '$_[%d]', $i ),
		);
		++$i;
	}

	$self;
}

sub _coderef_tail {
	my ( $self, $coderef ) = ( shift, @_ );
	$self->has_tail or return;

	my $size = @{ $self->tail };
	$coderef->add_line( sprintf(
		'@tail = splice( @_, -%d );',
		$size,
	) );

	$coderef->add_gap;

	my $i = 0;
	my $n = @{ $self->tail };
	for my $parameter ( @{ $self->tail } ) {
		$parameter->_make_code(
			signature   => $self,
			coderef     => $coderef,
			input_slot  => sprintf( '$tail[%d]', $i ),
			input_var   => '@tail',
			output_slot => sprintf( '$tail[%d]', $i ),
			output_var  => undef,
			index       => $i,
			type        => 'tail',
			display_var => sprintf( '$_[-%d]', $n - $i ),
		);
		++$i;
	}

	$self;
}

sub _coderef_parameters {
	my ( $self, $coderef ) = ( shift, @_ );

	if ( $self->is_named ) {
		
		if ( $self->list_to_named ) {
			require Type::Tiny::Enum;
			my $Keys = Type::Tiny::Enum->new( values => [ map { $_->name, $_->_all_aliases($self) } @{ $self->parameters } ] );
			$coderef->addf( 'my @positional;' );
			$coderef->addf( '{' );
			$coderef->increase_indent;
			$coderef->addf( 'last if ( @_ == 0 );' );
			$coderef->addf( 'last if ( @_ == 1 and %s );', HashRef->inline_check( '$_[0]' ) );
			$coderef->addf( 'last if ( @_ %% 2 == 0 and %s );', $Keys->inline_check( '$_[0]' ) );
			$coderef->addf( 'push @positional, shift @_;' );
			$coderef->addf( 'redo;' );
			$coderef->decrease_indent;
			$coderef->addf( '}' );
			$coderef->add_gap;
		}

		$coderef->add_line( sprintf(
			'%%in = ( @_ == 1 and %s ) ? %%{ $_[0] } : @_;',
			HashRef->inline_check( '$_[0]' ),
		) );
		$coderef->add_gap;

		for my $parameter ( @{ $self->parameters } ) {
			my $qname = B::perlstring( $parameter->name );
			$parameter->_make_code(
				signature   => $self,
				coderef     => $coderef,
				is_named    => 1,
				input_slot  => sprintf( '$in{%s}', $qname ),
				output_slot => sprintf( '$out{%s}', $qname ),
				display_var => sprintf( '$_{%s}', $qname ),
				key         => $parameter->name,
				type        => 'named_arg',
			);
		}
		
		if ( $self->list_to_named ) {
			$coderef->add_line( sprintf(
				'@positional and %s;',
				$self->_make_general_fail(
					coderef  => $coderef,
					message  => q{'Superfluous positional arguments'},
				),
			) );
		}
	}
	else {
		my $can_shortcut = $self->can_shortcut;
		my $head_size    = $self->has_head ? @{ $self->head } : 0;

		my $i = 0;
		for my $parameter ( @{ $self->parameters } ) {
			$parameter->_make_code(
				signature   => $self,
				coderef     => $coderef,
				is_named    => 0,
				input_slot  => sprintf( '$_[%d]', $i ),
				input_var   => '@_',
				output_slot => ( $can_shortcut ? undef : sprintf( '$_[%d]', $i ) ),
				output_var  => ( $can_shortcut ? undef : '@out' ),
				index       => $i,
				display_var => sprintf( '$_[%d]', $i + $head_size ),
			);
			++$i;
		}
	}
}

sub _coderef_slurpy {
	my ( $self, $coderef ) = ( shift, @_ );
	return unless $self->has_slurpy;

	my $parameter  = $self->slurpy;
	my $constraint = $parameter->type;
	my $slurp_into = $constraint->my_slurp_into;
	my $real_type  = $constraint->my_unslurpy;

	if ( $self->is_named ) {
		$coderef->add_line( 'my $SLURPY = \\%in;' );
	}
	elsif ( $real_type and $real_type->{uniq} == Any->{uniq} ) {

		$coderef->add_line( sprintf(
			'my $SLURPY = [ @_[ %d .. $#_ ] ];',
			scalar( @{ $self->parameters } ),
		) );
	}
	elsif ( $slurp_into eq 'HASH' ) {

		my $index = scalar( @{ $self->parameters } );
		$coderef->add_line( sprintf(
			'my $SLURPY = ( $#_ == %d and ( %s ) ) ? { %%{ $_[%d] } } : ( ( $#_ - %d ) %% 2 ) ? { @_[ %d .. $#_ ] } : %s;',
			$index,
			HashRef->inline_check("\$_[$index]"),
			$index,
			$index,
			$index,
			$self->_make_general_fail(
				coderef   => $coderef,
				message   => sprintf(
					qq{sprintf( "Odd number of elements in %%s", %s )},
					B::perlstring( ( $real_type or $constraint )->display_name ),
				),
			),
		) );
	}
	else {
	
		$coderef->add_line( sprintf(
			'my $SLURPY = [ @_[ %d .. $#_ ] ];',
			scalar( @{ $self->parameters } ),
		) );
	}

	$coderef->add_gap;

	$parameter->_make_code(
		signature   => $self,
		coderef     => $coderef,
		input_slot  => '$SLURPY',
		display_var => '$SLURPY',
		index       => 0,
		is_slurpy   => 1,
		$self->is_named
			? ( output_slot => sprintf( '$out{%s}', B::perlstring( $parameter->name ) ) )
			: ( output_var  => '@out' )
	);
}

sub _coderef_extra_names {
	my ( $self, $coderef ) = ( shift, @_ );

	return $self if $self->has_strictness && ! $self->strictness;

	require Type::Utils;
	my $english_list = 'Type::Utils::english_list';
	if ( $Type::Tiny::AvoidCallbacks ) {
		$english_list = 'join q{, } => ';
	}

	$coderef->add_line( '# Unrecognized parameters' );
	$coderef->add_line( sprintf(
		'%s if %skeys %%in;',
		$self->_make_general_fail(
			coderef   => $coderef,
			message   => "sprintf( q{Unrecognized parameter%s: %s}, keys( %in ) > 1 ? q{s} : q{}, $english_list( sort keys %in ) )",
		),
		defined( $self->strictness ) && $self->strictness ne 1
			? sprintf( '%s && ', $self->strictness )
			: ''
	) );
	$coderef->add_gap;
}

sub _coderef_end {
	my ( $self, $coderef ) = ( shift, @_ );

	if ( $self->{_is_signature_for} and $self->next ) {
		$coderef->add_variable( '$return_check_for_scalar', \ $self->returns_scalar->compiled_check )
			if $self->has_returns_scalar;
		$coderef->add_variable( '$return_check_for_list', \ $self->returns_list->compiled_check )
			if $self->has_returns_list;
	}

	if ( $self->bless and $self->oo_trace ) {
		my $package = $self->package;
		my $subname = $self->subname;
		if ( defined $package and defined $subname ) {
			$coderef->add_line( sprintf(
				'$out{"~~caller"} = %s;',
				B::perlstring( "$package\::$subname" ),
			) );
			$coderef->add_gap;
		}
	}

	$self->_coderef_end_extra( $coderef );
	$coderef->add_line( $self->_make_return_expression( is_early => 0, allow_full_statements => 1 ) . ';' );
	$coderef->{indent} =~ s/\t$//;
	$coderef->add_line( '}' );

	$self;
}

sub _coderef_end_extra {}

sub _make_return_list {
	my $self = shift;

	my @return_list;
	if ( $self->has_head ) {
		push @return_list, '@head';
	}

	if ( not $self->is_named ) {
		push @return_list, $self->can_shortcut ? '@_' : '@out';
	}
	elsif ( $self->named_to_list ) {
		push @return_list, map(
			sprintf( '$out{%s}', B::perlstring( $_ ) ),
			@{ $self->named_to_list },
		);
	}
	elsif ( $self->class ) {
		push @return_list, sprintf(
			'%s->%s( \%%out )',
			B::perlstring( $self->class ),
			$self->constructor || 'new',
		);
	}
	elsif ( $self->bless ) {
		push @return_list, sprintf(
			'bless( \%%out, %s )',
			B::perlstring( $self->bless ),
		);
	}
	else {
		push @return_list, '\%out';
	}

	if ( $self->has_tail ) {
		push @return_list, '@tail';
	}

	return @return_list;
}

sub _make_return_expression {
	my ( $self, %args ) = @_;

	my $list = join q{, }, $self->_make_return_list;

	if ( $self->next ) {
		if ( $self->{_is_signature_for} and ( $self->has_returns_list or $self->has_returns_scalar ) ) {
			my $call = sprintf '$__NEXT__->( %s )', $list;
			return $self->_make_typed_return_expression( $call );
		}
		elsif ( $list eq '@_' ) {
			return sprintf 'goto( $__NEXT__ )';
		}
		elsif ( $args{allow_full_statements} and not ( $args{is_early} or not exists $args{is_early} ) ) {
			# We are allowed to return full statements, not
			# forced to use do {...} to make an expression.
			return sprintf '@_ = ( %s ); goto $__NEXT__', $list;
		}
		else {
			return sprintf 'do { @_ = ( %s ); goto $__NEXT__ }', $list;
		}
	}
	elsif ( $args{is_early} or not exists $args{is_early} ) {
		return sprintf 'return( %s )', $list;
	}
	else {
		return sprintf '( %s )', $list;
	}
}

sub _make_typed_return_expression {
	my ( $self, $expr ) = @_;

	return sprintf 'wantarray ? %s : defined( wantarray ) ? %s : do { %s; undef; }',
		$self->has_returns_list ? $self->_make_typed_list_return_expression( $expr, $self->returns_list ) : $expr,
		$self->has_returns_scalar ? $self->_make_typed_scalar_return_expression( $expr, $self->returns_scalar ) : $expr,
		$expr;
}

sub _make_typed_scalar_return_expression {
	my ( $self, $expr, $constraint ) = @_;

	if ( $constraint->{uniq} == Any->{uniq} ) {
		return $expr;
	}
	elsif ( $constraint->can_be_inlined ) {
		return sprintf 'do { my $__RETURN__ = %s; ( %s ) ? $__RETURN__ : %s }',
			$expr,
			$constraint->inline_check( '$__RETURN__' ),
			$self->_make_constraint_fail( constraint => $constraint, varname => '$__RETURN__' );
	}
	else {
		return sprintf 'do { my $__RETURN__ = %s; $return_check_for_scalar->( $__RETURN__ ) ? $__RETURN__ : %s }',
			$expr,
			$self->_make_constraint_fail( constraint => $constraint, varname => '$__RETURN__' );
	}
}

sub _make_typed_list_return_expression {
	my ( $self, $expr, $constraint ) = @_;

	my $slurp_into = Slurpy->of( $constraint )->my_slurp_into;
	my $varname = $slurp_into eq 'HASH' ? '%__RETURN__' : '@__RETURN__';

	if ( $constraint->{uniq} == Any->{uniq} ) {
		return $expr;
	}
	elsif ( $constraint->can_be_inlined ) {
		return sprintf 'do { my %s = %s; my $__RETURN__ = \ %s; ( %s ) ? %s : %s }',
			$varname,
			$expr,
			$varname,
			$constraint->inline_check( '$__RETURN__' ),
			$varname,
			$self->_make_constraint_fail( constraint => $constraint, varname => '$__RETURN__', display_var => "\\$varname" );
	}
	else {
		return sprintf 'do { my %s = %s; my $__RETURN__ = \ %s; $return_check_for_list->( $__RETURN__ ) ? %s : %s }',
			$varname,
			$expr,
			$varname,
			$varname,
			$self->_make_constraint_fail( constraint => $constraint, varname => '$__RETURN__', display_var => "\\$varname" );
	}
}

sub _make_general_fail {
	my ( $self, %args ) = ( shift, @_ );

	return sprintf(
		$self->has_on_die
			? q{return( "Error::TypeTiny"->throw_cb( $__ON_DIE__, message => %s ) )}
			: q{"Error::TypeTiny"->throw( message => %s )},
		$args{message},
	);
}

sub _make_constraint_fail {
	my ( $self, %args ) = ( shift, @_ );

	return sprintf(
		$self->has_on_die
			? q{return( Type::Tiny::_failed_check( %d, %s, %s, varname => %s, on_die => $__ON_DIE__ ) )}
			: q{Type::Tiny::_failed_check( %d, %s, %s, varname => %s )},
		$args{constraint}{uniq},
		B::perlstring( $args{constraint}->display_name ),
		$args{varname},
		B::perlstring( $args{display_var} || $args{varname} ),
	);
}

sub _make_count_fail {
	my ( $self, %args ) = ( shift, @_ );

	my @counts;
	if ( $args{got} ) {
		push @counts, sprintf(
			'got => %s',
			$args{got},
		);
	}
	for my $c ( qw/ minimum maximum / ) {
		is_Int( $args{$c} ) or next;
		push @counts, sprintf(
			'%s => %s',
			$c,
			$args{$c},
		);
	}

	if ( my $package = $self->package and my $subname = $self->subname ) {
		push @counts, sprintf(
			'target => %s',
			B::perlstring( "$package\::$subname" ),
		) if $package ne '__ANON__' && $subname ne '__ANON__';
	}

	return sprintf(
		$self->has_on_die
			? q{return( "Error::TypeTiny::WrongNumberOfParameters"->throw_cb( $__ON_DIE__, %s ) )}
			: q{"Error::TypeTiny::WrongNumberOfParameters"->throw( %s )},
		join( q{, }, @counts ),
	);
}

sub class_attributes {
	my $self = shift;
	$self->{class_attributes} ||= $self->_build_class_attributes;
}

sub _build_class_attributes {
	my $self = shift;
	my %predicates;
	my %getters;

	my @parameters = @{ $self->parameters };
	if ( $self->has_slurpy ) {
		push @parameters, $self->slurpy;
	}

	for my $parameter ( @parameters ) {

		my $name = $parameter->name;
		if ( my $predicate = $parameter->predicate ) {
			$predicate =~ /^[^0-9\W]\w*$/
				or $self->_croak( "Bad accessor name: \"$predicate\"" );
			$predicates{$predicate} = $name;
		}
		if ( my $getter = $parameter->getter ) {
			$getter =~ /^[^0-9\W]\w*$/
				or $self->_croak( "Bad accessor name: \"$getter\"" );
			$getters{$getter} = $name;
		}
	}

	return {
		exists_predicates => \%predicates,
		getters           => \%getters,
	};
}

sub make_class {
	my $self = shift;
	
	my $env = uc( $ENV{PERL_TYPE_PARAMS_XS} || 'XS' );
	if ( $env eq 'PP' or $ENV{PERL_ONLY} ) {
		$self->make_class_pp;
	}

	$self->make_class_xs;
}

sub make_class_xs {
	my $self = shift;

	eval {
		require Class::XSAccessor;
		'Class::XSAccessor'->VERSION( '1.17' );
		1;
	} or return $self->make_class_pp;

	my $attr = $self->class_attributes;

	'Class::XSAccessor'->import(
		class => $self->bless,
		replace => 1,
		%$attr,
	);
}

sub make_class_pp {
	my $self = shift;

	my $code = $self->make_class_pp_code;
	do {
		local $@;
		eval( $code ) or die( $@ );
	};
}

sub make_class_pp_code {
	my $self = shift;

	return ''
		unless $self->is_named && $self->bless && !$self->named_to_list;

	my $coderef = $self->_new_code_accumulator;
	my $attr    = $self->class_attributes;

	$coderef->add_line( '{' );
	$coderef->{indent} = "\t";
	$coderef->add_line( sprintf( 'package %s;', $self->bless ) );
	$coderef->add_line( 'use strict;' );
	$coderef->add_line( 'no warnings;' );

	for my $function ( sort keys %{ $attr->{getters} } ) {
		my $slot = $attr->{getters}{$function};
		$coderef->add_line( sprintf(
			'sub %s { $_[0]{%s} }',
			$function,
			B::perlstring( $slot ),
		) );
	}

	for my $function ( sort keys %{ $attr->{exists_predicates} } ) {
		my $slot = $attr->{exists_predicates}{$function};
		$coderef->add_line( sprintf(
			'sub %s { exists $_[0]{%s} }',
			$function,
			B::perlstring( $slot ),
		) );
	}
	
	$coderef->add_line( '1;' );
	$coderef->{indent} = "";
	$coderef->add_line( '}' );

	return $coderef->code;
}

sub return_wanted {
	my $self = shift;
	my $coderef = $self->coderef;

	if ( $self->{want_source} ) {
		return $coderef->code;
	}
	elsif ( $self->{want_object} ) { # undocumented for now
		return $self;
	}
	elsif ( $self->{want_details} ) {
		return {
			min_args         => $self->{min_args},
			max_args         => $self->{max_args},
			environment      => $coderef->{env},
			source           => $coderef->code,
			closure          => $coderef->compile,
			named            => $self->is_named,
			class_definition => $self->make_class_pp_code,
		};
	}

	return $coderef->compile;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Params::Signature - internal representation of a function signature

=head1 STATUS

This module is not covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is mostly internal code, but can be used to provide basic introspection
for signatures.

=head2 Constructors

=over

=item C<< new(%attributes) >>

=item C<< new_from_compile($style, %attributes) >>

=item C<< new_from_v2api(\%attributes) >>

=back

=head2 Attributes

All attributes are read-only.

=over

=item C<< package >> B<ClassName>

The package we're providing a signature for. Will be used to look up any
stringy type names.

=item C<< subname >> B<Str>

The sub we're providing a signature for.

=item C<< description >> B<Str>

=item C<< method >> B<< ArrayRef[InstanceOf['Type::Params::Parameter']] >>

=item C<< head >> B<< ArrayRef[InstanceOf['Type::Params::Parameter']] >>

=item C<< tail >> B<< ArrayRef[InstanceOf['Type::Params::Parameter']] >>

=item C<< parameters >> B<< ArrayRef[InstanceOf['Type::Params::Parameter']] >>

=item C<< slurpy >> B<< InstanceOf['Type::Params::Parameter'] >>

=item C<< on_die >> B<CodeRef>

=item C<< strictness >> B<< Bool|ScalarRef >>

=item C<< next >> B<CodeRef>

=item C<< goto_next >> B<CodeRef>

Alias for C<next>.

=item C<< can_shortcut >> B<Bool>

Indicates whether the signature has no potential to alter C<< @_ >> allowing
it to be returned without being copied if type checks pass. Generally speaking,
you should not provide this to the constructor and rely on
Type::Params::Signature to figure it out.

=item C<< coderef >> B<< InstanceOf['Eval::TypeTiny::CodeAccumulator'] >>

You probably don't want to provide this to the constructor. The whole point
of this module is to build it for you!

=back

=head3 Attributes related to named parameters

=over

=item C<< is_named >> B<Bool>

=item C<< allow_dash >> B<Bool>

=item C<< bless >> B<Bool|ClassName>

=item C<< class >> B<ClassName>

=item C<< constructor >> B<Str>

=item C<< class_attributes >> B<HashRef>

HashRef suitable for passing to the C<import> method of
L<Class::XSAccessor>. A default will be generated based
on C<parameters>

=item C<< named_to_list >> B<< ArrayRef >>

Can be coerced from a bool based on C<parameters>.

=item C<< list_to_named >> B<< Bool >>

=item C<< oo_trace >> B<Bool>

Defaults to true. Indicates whether blessed C<< $arg >> hashrefs created by
the signature will include a C<< '~~caller' >> key.

=back

=head3 Bare attributes

These attributes may be passed to the constructors and may do something,
but no methods are provided to access the values later.

=over

=item C<< positional >> or C<< pos >> B<ArrayRef>

=item C<< named >> B<ArrayRef>

=item C<< multiple >> or C<< multi >> B<ArrayRef>

=item C<< returns >> B<Bool>

Shortcut for setting C<returns_scalar> and C<returns_list> simultaneously.

=item C<< want_source >> B<Bool>

=item C<< want_details >> B<Bool>

=item C<< want_object >> B<Bool>

=item C<< rationalize_slurpies >> B<Bool>

=back

=head2 Methods

=head3 Predicates

Predicate methods return true/false to indicate the presence or absence of
attributes.

=over

=item C<< has_description >>

=item C<< has_head >>

=item C<< has_tail >>

=item C<< has_parameters >>

=item C<< has_slurpy >>

=item C<< has_on_die >>

=item C<< has_strictness >>

=item C<< has_returns_scalar >>

=item C<< has_returns_list >>

=back

=head3 Class making methods

These methods will be called automatically during object construction
and should not typically be called. They are public methods in case
it is desired to subclass Type::Params::Signature.

=over

=item C<< make_class_pp >>

Builds the class specified in C<bless> by evaluating Perl code.

=item C<< make_class_xs >>

Builds the class specified in C<bless> using L<Class::XSAccessor>.

=item C<< make_class >>

Calls either C<make_class_pp> or C<make_class_xs>.

=item C<< make_class_pp_code >>

Generates the code for C<make_class_pp>.

=back

=head3 Other methods

=over

=item C<< BUILD >>

Called by the constructors. You should not call this.

=item C<< return_wanted >>

Normally returns the signature coderef, unless C<want_source>, C<want_details>,
or C<want_object> were provided to the constructor, in which case it will
return the source code for the coderef, a hashref of details, or C<< $self >>.

=back

=head1 ENVIRONMENT

=over

=item C<PERL_TYPE_PARAMS_XS>

Affects the building of accessors for C<< $arg >> objects. If set to true,
will use L<Class::XSAccessor>. If set to false, will use pure Perl. If this
environment variable does not exist, will use Class::XSAccessor.

If Class::XSAccessor is not installed or is too old, pure Perl will always
be used as a fallback.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 SEE ALSO

L<Type::Params>, L<Type::Params::Parameter>, L<Type::Params::Alternatives>.

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
