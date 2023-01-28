package Type::Tiny::Bitfield;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Tiny::Bitfield::AUTHORITY = 'cpan:TOBYINK';
	$Type::Tiny::Bitfield::VERSION   = '2.002001';
}

$Type::Tiny::Bitfield::VERSION =~ tr/_//d;

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

use Exporter::Tiny 1.004001 ();
use Type::Tiny ();
our @ISA = qw( Type::Tiny Exporter::Tiny );

sub _is_power_of_two { not $_[0] & $_[0]-1 }

sub _exporter_fail {
	my ( $class, $type_name, $values, $globals ) = @_;
	my $caller = $globals->{into};
	my $type = $class->new(
		name      => $type_name,
		values    => { %$values },
		#coercion  => 1,
	);
	$INC{'Type/Registry.pm'}
		? 'Type::Registry'->for_class( $caller )->add_type( $type, $type_name )
		: ( $Type::Registry::DELAYED{$caller}{$type_name} = $type )
		unless( ref($caller) or $caller eq '-lexical' or $globals->{'lexical'} );
	return map +( $_->{name} => $_->{code} ), @{ $type->exportables };
}

sub new {
	my $proto = shift;
	
	my %opts = ( @_ == 1 ) ? %{ $_[0] } : @_;
	_croak
		"Bitfield type constraints cannot have a parent constraint passed to the constructor"
		if exists $opts{parent};
	_croak
		"Bitfield type constraints cannot have a constraint coderef passed to the constructor"
		if exists $opts{constraint};
	_croak
		"Bitfield type constraints cannot have a inlining coderef passed to the constructor"
		if exists $opts{inlined};
	_croak "Need to supply hashref of values"
		unless exists $opts{values};
	
	require Types::Common::Numeric;
	$opts{parent} = Types::Common::Numeric::PositiveOrZeroInt();
	
	my $ALL = 0;
	my %already = ();
	for my $value ( values %{ $opts{values} } ) {
		_croak "Not a positive power of 2 in a bitfield: $value"
			unless _is_power_of_two $value;
		_croak "Duplicate value in a bitfield: $value"
			if $already{$value}++;
		$ALL |= ( 0 + $value );
	}
	$opts{ALL} = $ALL;
	
	# TODO: ensure all keys in $opt{values} are caps
	
	$opts{constraint} = sub {
		not shift() & ~$ALL;
	};
	
	# TODO: coercion
	
	return $proto->SUPER::new( %opts );
} #/ sub new

sub values {
	$_[0]{values}
}

sub _lockdown {
	my ( $self, $callback ) = @_;
	$callback->( $self->{values} );
}

sub exportables {
	my ( $self, $base_name ) = @_;
	if ( not $self->is_anon ) {
		$base_name ||= $self->name;
	}
	
	my $exportables = $self->SUPER::exportables( $base_name );
	
	require Eval::TypeTiny;
	require B;
	
	for my $key ( keys %{ $self->values } ) {
		my $value = $self->values->{$key};
		push @$exportables, {
			name => uc( sprintf '%s_%s', $base_name, $key ),
			tags => [ 'constants' ],
			code => Eval::TypeTiny::eval_closure(
				source      => sprintf( 'sub () { %d }', $value ),
				environment => {},
			),
		};
	}
	
	return $exportables;
}

sub can_be_inlined {
	!!1;
}

sub inline_check {
	my ( $self, $var ) = @_;
	
	return sprintf(
		'( %s and not %s & ~%d )',
		Types::Common::Numeric::PositiveOrZeroInt()->inline_check( $var ),
		$var,
		$self->{ALL},
	);
}

sub AUTOLOAD {
	my $self = shift;
	my ( $m ) = ( our $AUTOLOAD =~ /::(\w+)$/ );
	return if $m eq 'DESTROY';
	if ( ref $self and exists $self->{values}{$m} ) {
		return $self->{values}{$m};
	}
	return $self->SUPER::AUTOLOAD( @_ );
}

sub can {
	my ( $self, $m ) = ( shift, @_ );
	if ( ref $self and exists $self->{values}{$m} ) {
		return sub () { $self->{values}{$m} };
	}
	return $self->SUPER::can( @_ );
}

1;
