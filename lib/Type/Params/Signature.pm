package Type::Params::Signature;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.008 ) { require Devel::TypeTiny::Perl56Compat }
	if ( $] < 5.010 ) { require Devel::TypeTiny::Perl58Compat }
}

BEGIN {
	$Type::Params::Signature::AUTHORITY  = 'cpan:TOBYINK';
	$Type::Params::Signature::VERSION    = '1.015_000';
}

$Type::Params::Signature::VERSION =~ tr/_//d;

use B ();
use Types::TypeTiny qw( -is -types to_TypeTiny );
use Types::Standard qw( -is -types -assert );
use Type::Utils qw( dwim_type );
use Type::Params::Coderef;
use Type::Params::Parameter;

sub _croak {
	require Carp;
	Carp::croak( pop );
}

sub new {
	my $class = shift;
	my %self  = @_ == 1 ? %{$_[0]} : @_;
	my $self = bless \%self, $class;
	$self->BUILD;
	return $self;
}

{
	my $klass_id;
	my %klass_cache;
	sub BUILD {
		my $self = shift;

		$self->{class_prefix} ||= 'Type::Params::OO::Klass';

		if ( defined $self->{bless} and $self->{bless} eq 1 ) {
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
	no warnings 'uninitialized';
	join(
		'|',
		map sprintf( '%s*%s*%s', $_->name, $_->getter, $_->predicate ),
		sort { $a->{name} cmp $b->{name} } (
			@{ $self->parameters || [] },
			( $self->has_slurpy ? $self->slurpy : () )
		)
	);
}

sub _parameters_from_list {
	my ( $class, $style, $list, %opts ) = @_;
	my @return;
	my $is_named = ( $style eq 'named' );

	while ( @$list ) {
		if ( $is_named and is_Str( $list->[0] ) and is_HashRef( $list->[1] ) and $list->[1]{slurpy} ) {
			last;
		}
		elsif ( !$is_named and is_HashRef( $list->[0] ) and $list->[0]{slurpy} ) {
			last;
		}

		my %param_opts;
		if ( $is_named ) {
			$param_opts{name} = assert_Str( shift( @$list ) );
		}
		my $type = shift( @$list );
		if ( is_HashRef( $list->[0] ) and not $list->[0]{slurpy} ) {
			%param_opts = ( %param_opts, %{ +shift( @$list ) } );
		}
		$param_opts{type} =
			is_Int($type)  ? ( $type ? Any : do { $param_opts{optional} = !!1; Any; } ) :
			is_Str($type)  ? dwim_type( $type, $opts{package} ? ( for => $opts{package} ) : () ) :
			to_TypeTiny( $type );

		my $parameter = 'Type::Params::Parameter'->new( %param_opts );
		push @return, $parameter;
	}

	return \@return;
}

sub new_from_compile {
	my $class = shift;
	my $style = shift;
	my $is_named = ( $style eq 'named' );

	my %opts  = ();
	while ( is_HashRef( $_[0] )  and not $_[0]{slurpy} ) {
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

	if ( @$list ) {
		my $name;
		if ( $is_named ) {
			$name = assert_Str( shift @$list );
		}
		assert_HashRef( $list->[0] );
		$list->[0]{slurpy} or die;

		my %slurpy = %{ shift @$list };
		$slurpy{type} = $slurpy{slurpy};
		$slurpy{name} = $name if defined $name;
		if ( is_HashRef $list->[0] ) {
			%slurpy = ( %slurpy, %{ shift @$list } );
		}
		$opts{slurpy} = 'Type::Params::Parameter'->new( %slurpy );

		if ( @$list ) {
			$class->_croak( 'Parameter following slurpy parameter' );
		}
	}

	return $class->new( %opts );
}

sub package       { $_[0]{package} }
sub subname       { $_[0]{subname} }
sub description   { $_[0]{description} }     sub has_description   { exists $_[0]{description} }
sub head          { $_[0]{head} }            sub has_head          { exists $_[0]{head} }
sub tail          { $_[0]{tail} }            sub has_tail          { exists $_[0]{tail} }
sub parameters    { $_[0]{parameters} }      sub has_parameters    { exists $_[0]{parameters} }
sub slurpy        { $_[0]{slurpy} }          sub has_slurpy        { exists $_[0]{slurpy} }
sub on_die        { $_[0]{on_die} }          sub has_on_die        { exists $_[0]{on_die} }

sub is_named      { $_[0]{is_named} }
sub bless         { $_[0]{bless} }
sub class         { $_[0]{class} }
sub constructor   { $_[0]{constructor} }
sub named_to_list { $_[0]{named_to_list} }
sub oo_trace      { $_[0]{oo_trace} }

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
	my $coderef = 'Type::Params::Coderef'->new(
		description => $self->description
			|| sprintf( 'parameter validation for "%s::%s"', $self->package, $self->subname )
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

	$self->_coderef_start_extra( $coderef );

	my $extravars = '';
	if ( $self->has_head ) {
		$extravars .= ', @head';
	}
	if ( $self->has_tail ) {
		$extravars .= ', @tail';
	}

	if ( $self->is_named ) {
		$coderef->add_line( "my ( \%return, \%in, \%tmp, \$tmp, \$dtmp$extravars );" );
	}
	elsif ( $self->can_shortcut ) {
		$coderef->add_line( "my ( \%tmp, \$tmp$extravars );" );
	}
	else {
		$coderef->add_line( "my ( \@return, \%tmp, \$tmp, \$dtmp$extravars );" );
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

	my $headtail = 0;
	$headtail += @{ $self->head } if $self->has_head;
	$headtail += @{ $self->tail } if $self->has_tail;

	my $is_named = $self->is_named;
	my $min_args = 0;
	my $max_args = 0;
	my $seen_optional = 0;
	for my $parameter ( @{ $self->parameters || [] } ) {
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

	if ( $is_named ) {
		my $args_if_hashref  = $headtail + 1;
		my $hashref_index    = @{ $self->head || [] };
		my $arity_if_hash    = $headtail % 2;
		my $min_args_if_hash = $headtail + ( 2 * $min_args );
		my $max_args_if_hash = defined( $max_args )
			? ( $headtail + ( 2 * $max_args ) )
			: undef;

		require List::Util;
		$self->{min_args} = List::Util::min( $args_if_hashref, $min_args_if_hash );
		if ( defined $max_args_if_hash ) {
			$self->{max_args} = List::Util::max( $args_if_hashref, $max_args_if_hash );
		}

		my $extra_conditions = '';
		if ( defined $max_args_if_hash and $min_args_if_hash==$max_args_if_hash ) {
			$extra_conditions .= " && \@_ == $min_args_if_hash"
		}
		else {
			$extra_conditions .= " && \@_ >= $min_args_if_hash"
				if $min_args_if_hash;
			$extra_conditions .= " && \@_ <= $max_args_if_hash"
				if defined $max_args_if_hash;
		}

		$coderef->add_line( sprintf(
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

		if ( $min_args and defined $max_args and $min_args == $max_args ) {
			$coderef->add_line( sprintf(
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
			$coderef->add_line( sprintf(
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
		elsif ( $min_args ) {
			$coderef->add_line( sprintf(
				"\@_ >= %d\n\tor %s;",
				$min_args,
				$self->_make_count_fail(
					coderef   => $coderef,
					minimum   => $min_args,
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

		$coderef->add_line( sprintf(
			'%%in = ( @_ == 1 and %s ) ? %%{ $_[0] } : @_;',
			HashRef->inline_check( '$_[0]' ),
		) );

		$coderef->add_gap;

		for my $parameter ( @{ $self->parameters || [] } ) {
			my $qname = B::perlstring( $parameter->name );
			$parameter->_make_code(
				signature   => $self,
				coderef     => $coderef,
				is_named    => 1,
				input_slot  => sprintf( '$in{%s}', $qname ),
				output_slot => sprintf( '$return{%s}', $qname ),
				display_var => sprintf( '$_{%s}', $qname ),
				key         => $parameter->name,
				type        => 'named_arg',
			);
		}
	}
	else {
		my $can_shortcut = $self->can_shortcut;
		my $head_size    = $self->has_head ? @{ $self->head } : 0;

		my $i = 0;
		for my $parameter ( @{ $self->parameters || [] } ) {
			$parameter->_make_code(
				signature   => $self,
				coderef     => $coderef,
				is_named    => 0,
				input_slot  => sprintf( '$_[%d]', $i ),
				input_var   => '@_',
				output_slot => ( $can_shortcut ? undef : sprintf( '$_[%d]', $i ) ),
				output_var  => ( $can_shortcut ? undef : '@return' ),
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

	if ( $self->is_named ) {
		$coderef->add_line( 'my $SLURPY = \\%in;' );
	}
	elsif ( $constraint->{uniq} == Any->{uniq} ) {

		$coderef->add_line( sprintf(
			'my $SLURPY = { @_[ %d .. $#_ ] };',
			scalar( @{ $self->parameters || [] } ),
		) );
	}
	elsif ( $constraint->is_a_type_of( HashRef )
		or $constraint->is_a_type_of( Map )
		or $constraint->is_a_type_of( Dict ) ) {

		my $index = scalar( @{ $self->parameters || [] } );
		$coderef->add_line( sprintf(
			'my $SLURPY = ( %s ) ? { %%{ $_[%d] } } : ( ( $#_ - %d ) %% 2 ) ? { @_[ %d .. $#_ ] } : %s;',
			HashRef->inline_check("\$_[$index]"),
			$index,
			$index,
			$index,
			$self->_make_general_fail(
				coderef   => $coderef,
				message   => sprintf(
					qq{sprintf( "Odd number of elements in %%s", %s )},
					B::perlstring( "$constraint" ),
				),
			),
		) );
	}
	elsif ( $constraint->is_a_type_of( ArrayRef )
		or $constraint->is_a_type_of( Tuple )
		or $constraint->is_a_type_of( CycleTuple ) ) {
	
		$coderef->add_line( sprintf(
			'my $SLURPY = [ @_[ %d .. $#_ ] ];',
			scalar( @{ $self->parameters || [] } ),
		) );
	}
	else {
		$self->_croak( "Slurpy parameter not of type HashRef or ArrayRef" );
	}

	$coderef->add_gap;

	$parameter->_make_code(
		signature   => $self,
		coderef     => $coderef,
		input_slot  => '$SLURPY',
		display_var => '$SLURPY',
		index       => 0,
		$self->is_named
			? ( output_slot => sprintf( '$return{%s}', B::perlstring( $parameter->name ) ) )
			: ( output_var  => '@return' )
	);
}

sub _coderef_extra_names {
	my ( $self, $coderef ) = ( shift, @_ );

	$coderef->add_line( '# Unrecognized parameters' );
	$coderef->add_line( sprintf(
		'%s if keys %%in;',
		$self->_make_general_fail(
			coderef   => $coderef,
			message   => 'sprintf( q{Unrecognized parameter%s: %s}, keys( %in ) > 1 ? q{s} : q{}, join( q{, }, sort keys %in ) )',
		),
	) );
	$coderef->add_gap;
}

sub _coderef_end {
	my ( $self, $coderef ) = ( shift, @_ );

	if ( $self->bless and $self->oo_trace) {
		my $package = $self->package;
		my $subname = $self->subname;

		$coderef->add_line( sprintf(
			'$return{"~~caller"} = %s;',
			B::perlstring( "$package\::$subname" ),
		) );
		$coderef->add_gap;
	}

	$self->_coderef_end_extra( $coderef );
	$coderef->add_line( $self->_make_return_expression . ';' );
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
		push @return_list, $self->can_shortcut ? '@_' : '@return';
	}
	elsif ( is_ArrayRef( $self->named_to_list ) ) {
		push @return_list, map(
			sprintf( '$return{%s}', B::perlstring( $_ ) ),
			@{ $self->named_to_list },
		);
	}
	elsif ( $self->named_to_list ) {
		push @return_list, map(
			sprintf( '$return{%s}', B::perlstring( $_->name ) ),
			@{ $self->parameters || [] },
		);
	}
	elsif ( $self->class ) {
		push @return_list, sprintf(
			'%s->%s( \%%return )',
			B::perlstring( $self->class ),
			$self->constructor || 'new',
		);
	}
	elsif ( $self->bless ) {
		push @return_list, sprintf(
			'bless( \%%return, %s )',
			B::perlstring( $self->bless ),
		);
	}
	else {
		push @return_list, '\%return';
	}

	if ( $self->has_tail ) {
		push @return_list, '@tail';
	}

	return @return_list;
}

sub _make_return_expression {
	my $self = shift;
	sprintf 'return( %s )', join( q{, }, $self->_make_return_list );
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

	for my $parameter ( @{ $self->parameters || [] } ) {

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
	if ( $env eq 'PP' ) {
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

	my $coderef = 'Type::Params::Coderef'->new;
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
	elsif ( $self->{want_details} ) {
		return {
			min_args    => $self->{min_args},
			max_args    => $self->{max_args},
			environment => $coderef->{env},
			source      => $coderef->code,
			closure     => $coderef->compile,
			named       => $self->is_named,
		};
	}

	return $coderef->compile;
}

1;
