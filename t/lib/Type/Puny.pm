# This is just a copy of Type::Nano.
#

use 5.008001;
use strict;
use warnings;

use Scalar::Util ();

package Type::Puny;

use Exporter::Shiny qw(
	Any Defined Undef Ref ArrayRef HashRef CodeRef Object Str Bool Num Int Object
	class_type role_type duck_type union intersection enum type
);

# Built-in type constraints
#

our %TYPES;

sub Any () {
	$TYPES{Any} ||= __PACKAGE__->new(
		name         => 'Any',
		constraint   => sub { !!1 },
	);
}

sub Defined () {
	$TYPES{Defined} ||= __PACKAGE__->new(
		name         => 'Defined',
		parent       => Any,
		constraint   => sub { defined $_ },
	);
}

sub Undef () {
	$TYPES{Undef} ||= __PACKAGE__->new(
		name         => 'Undef',
		parent       => Any,
		constraint   => sub { !defined $_ },
	);
}

sub Ref () {
	$TYPES{Ref} ||= __PACKAGE__->new(
		name         => 'Ref',
		parent       => Defined,
		constraint   => sub { ref $_ },
	);
}

sub ArrayRef () {
	$TYPES{ArrayRef} ||= __PACKAGE__->new(
		name         => 'ArrayRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'ARRAY' },
	);
}

sub HashRef () {
	$TYPES{HashRef} ||= __PACKAGE__->new(
		name         => 'HashRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'HASH' },
	);
}

sub CodeRef () {
	$TYPES{CodeRef} ||= __PACKAGE__->new(
		name         => 'CodeRef',
		parent       => Ref,
		constraint   => sub { ref $_ eq 'CODE' },
	);
}

sub Object () {
	$TYPES{Object} ||= __PACKAGE__->new(
		name         => 'Object',
		parent       => Ref,
		constraint   => sub { Scalar::Util::blessed($_) },
	);
}

sub Bool () {
	$TYPES{Bool} ||= __PACKAGE__->new(
		name         => 'Bool',
		parent       => Any,
		constraint   => sub { !defined($_) or (!ref($_) and { 1 => 1, 0 => 1, '' => 1 }->{$_}) },
	);
}

sub Str () {
	$TYPES{Str} ||= __PACKAGE__->new(
		name         => 'Str',
		parent       => Defined,
		constraint   => sub { !ref $_ },
	);
}

sub Num () {
	$TYPES{Num} ||= __PACKAGE__->new(
		name         => 'Num',
		parent       => Str,
		constraint   => sub { Scalar::Util::looks_like_number($_) },
	);
}

sub Int () {
	$TYPES{Int} ||= __PACKAGE__->new(
		name         => 'Int',
		parent       => Num,
		constraint   => sub { /\A-?[0-9]+\z/ },
	);
}

sub class_type ($) {
	my $class = shift;
	$TYPES{CLASS}{$class} ||= __PACKAGE__->new(
		name         => $class,
		parent       => Object,
		constraint   => sub { $_->isa($class) },
		class        => $class,
	);
}

sub role_type ($) {
	my $role = shift;
	$TYPES{ROLE}{$role} ||= __PACKAGE__->new(
		name         => $role,
		parent       => Object,
		constraint   => sub { my $meth = $_->can('DOES') || $_->can('isa'); $_->$meth($role) },
		role         => $role,
	);
}

sub duck_type {
	my $name    = ref($_[0]) ? '__ANON__' : shift;
	my @methods = sort( ref($_[0]) ? @{+shift} : @_ );
	my $methods = join "|", @methods;
	$TYPES{DUCK}{$methods} ||= __PACKAGE__->new(
		name         => $name,
		parent       => Object,
		constraint   => sub { my $obj = $_; $obj->can($_)||return !!0 for @methods; !!1 },
		methods      => \@methods,
	);
}

sub enum {
	my $name   = ref($_[0]) ? '__ANON__' : shift;
	my @values = sort( ref($_[0]) ? @{+shift} : @_ );
	my $values = join "|", map quotemeta, @values;
	my $regexp = qr/\A(?:$values)\z/;
	$TYPES{ENUM}{$values} ||= __PACKAGE__->new(
		name         => $name,
		parent       => Str,
		constraint   => sub { $_ =~ $regexp },
		values       => \@values,
	);
}

sub union {
	my $name  = ref($_[0]) ? '__ANON__' : shift;
	my @types = ref($_[0]) ? @{+shift} : @_;
	__PACKAGE__->new(
		name         => $name,
		constraint   => sub { my $val = $_; $_->check($val) && return !!1 for @types; !!0 },
		types        => \@types,
	);
}

sub intersection {
	my $name  = ref($_[0]) ? '__ANON__' : shift;
	my @types = ref($_[0]) ? @{+shift} : @_;
	__PACKAGE__->new(
		name         => $name,
		constraint   => sub { my $val = $_; $_->check($val) || return !!0 for @types; !!1 },
		types        => \@types,
	);
}

sub type {
	my $name    = ref($_[0]) ? '__ANON__' : shift;
	my $coderef = shift;
	__PACKAGE__->new(
		name         => $name,
		constraint   => $coderef,
	);
}

# OO interface
#

sub DOES {
	my $proto = shift;
	my ($role) = @_;
	return !!1 if {
		'Type::API::Constraint'              => 1,
		'Type::API::Constraint::Constructor' => 1,
	}->{$role};
	"UNIVERSAL"->can("DOES") ? $proto->SUPER::DOES(@_) : $proto->isa(@_);
}

sub new { # Type::API::Constraint::Constructor
	my $class = ref($_[0]) ? ref(shift) : shift;
	my $self  = bless { @_ == 1 ? %{+shift} : @_ } => $class;
	
	$self->{constraint} ||= sub { !!1 };
	unless ($self->{name}) {
		require Carp;
		Carp::croak("Requires both `name` and `constraint`");
	}
	
	$self;
}

sub check { # Type::API::Constraint
	my $self = shift;
	my ($value) = @_;
	
	if ($self->{parent}) {
		return unless $self->{parent}->check($value);
	}
	
	local $_ = $value;
	$self->{constraint}->($value);
}

sub get_message { # Type::API::Constraint
	my $self = shift;
	my ($value) = @_;
	
	require B;
	!defined($value)
		? sprintf("Undef did not pass type constraint %s", $self->{name})
		: ref($value)
			? sprintf("Reference %s did not pass type constraint %s", $value, $self->{name})
			: sprintf("Value %s did not pass type constraint %s", B::perlstring($value), $self->{name});
}

# Overloading
#

{
	my $nil = sub {};
	sub _install_overloads
	{
		no strict 'refs';
		no warnings 'redefine', 'once';
		if ($] < 5.010) {
			require overload;
			push @_, fallback => 1;
			goto \&overload::OVERLOAD;
		};
		my $class = shift;
		*{$class . '::(('} = sub {};
		*{$class . '::()'} = sub {};
		*{$class . '::()'} = do { my $x = 1; \$x };
		while (@_)
		{
			my $f = shift;
			#*{$class . '::(' . $f} = $nil; # cargo culting overload.pm
			#*{$class . '::(' . $f} = shift;
			*{$class . '::(' . $f} = ref $_[0] ? shift : do { my $m = shift; sub { shift->$m(@_) } };
		}
	}
}

__PACKAGE__ ->_install_overloads(
	'bool'  => sub { 1 },
	'""'    => sub { shift->{name} },
	'&{}'   => sub {
		my $self = shift;
		sub {
			my ($value) = @_;
			$self->check($value) or do {
				require Carp;
				Carp::croak($self->get_message($value));
			};
		};
	},
);

1;
