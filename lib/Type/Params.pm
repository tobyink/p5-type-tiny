package Type::Params;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Params::AUTHORITY = 'cpan:TOBYINK';
	$Type::Params::VERSION   = '2.007_008';
}

$Type::Params::VERSION =~ tr/_//d;

use B qw();
use Eval::TypeTiny qw( eval_closure set_subname );
use Scalar::Util qw( refaddr );
use Error::TypeTiny;
use Error::TypeTiny::Assertion;
use Error::TypeTiny::WrongNumberOfParameters;
use Types::Standard ();
use Types::TypeTiny ();

require Exporter::Tiny;
our @ISA = 'Exporter::Tiny';

our @EXPORT = qw(
	compile compile_named
);

our @EXPORT_OK = qw(
	compile_named_oo
	validate validate_named
	multisig
	Invocant ArgsObject
	wrap_subs wrap_methods
	signature signature_for signature_for_func signature_for_method
);

our %EXPORT_TAGS = (
	compile  => [ qw( compile compile_named compile_named_oo ) ],
	wrap     => [ qw( wrap_subs wrap_methods ) ],
	sigs     => [ qw( signature signature_for ) ],
	validate => [ qw( validate validate_named ) ],
	sigplus  => [ qw( signature signature_for signature_for_func signature_for_method ) ],
	
	v1       => [ qw( compile compile_named ) ],      # Old default
	v2       => [ qw( signature signature_for ) ],    # New recommendation
);

{
	my $Invocant;
	
	sub Invocant () {
		$Invocant ||= do {
			require Type::Tiny::Union;
			'Type::Tiny::Union'->new(
				name             => 'Invocant',
				type_constraints => [
					Types::Standard::Object(),
					Types::Standard::ClassName(),
				],
			);
		};
	} #/ sub Invocant
	
	my $ArgsObject;
	
	sub ArgsObject (;@) {
		$ArgsObject ||= do {
			'Type::Tiny'->new(
				name                 => 'ArgsObject',
				parent               => Types::Standard::Object(),
				constraint           => q{ ref($_) =~ qr/^Type::Params::OO::/ },
				constraint_generator => sub {
					Type::Tiny::check_parameter_count_for_parameterized_type( 'Type::Params', 'ArgsObject', \@_, 1, 1 );
					my $param = Types::Standard::assert_Str( shift );
					sub { defined( $_->{'~~caller'} ) and $_->{'~~caller'} eq $param };
				},
				inline_generator => sub {
					my $param  = shift;
					my $quoted = B::perlstring( $param );
					sub {
						my $var = pop;
						return (
							Types::Standard::Object()->inline_check( $var ),
							sprintf( q{ ref(%s) =~ qr/^Type::Params::OO::/ }, $var ),
							sprintf(
								q{ do { use Scalar::Util (); Scalar::Util::reftype(%s) eq 'HASH' } }, $var
							),
							sprintf(
								q{ defined((%s)->{'~~caller'}) && ((%s)->{'~~caller'} eq %s) }, $var, $var,
								$quoted
							),
						);
					};
				},
			);
		};
		
		@_ ? $ArgsObject->parameterize( @{ $_[0] } ) : $ArgsObject;
	} #/ sub ArgsObject (;@)
	
	&Scalar::Util::set_prototype( \&ArgsObject, ';$' )
		if Eval::TypeTiny::NICE_PROTOTYPES;
}

sub signature {
	if ( @_ % 2 ) {
		require Error::TypeTiny;
		Error::TypeTiny::croak( "Expected even-sized list of arguments" );
	}
	my ( %opts ) = @_;
	$opts{next} ||= delete $opts{goto_next} if exists $opts{goto_next};

	my $for = [ caller( 1 + ( $opts{caller_level} || 0 ) ) ]->[3] || ( ( $opts{package} || '__ANON__' ) . '::__ANON__' );
	my ( $pkg, $sub ) = ( $for =~ /^(.+)::(\w+)$/ );
	$opts{package} ||= $pkg;
	$opts{subname} ||= $sub;

	require Type::Params::Signature;
	'Type::Params::Signature'->new_from_v2api( \%opts )->return_wanted;
}

sub signature_for {
	if ( not @_ % 2 ) {
		require Error::TypeTiny;
		Error::TypeTiny::croak( "Expected odd-sized list of arguments; did you forget the function name?" );
	}
	my ( $function, %opts ) = @_;
	my $package = $opts{package} || caller( $opts{caller_level} || 0 );
	$opts{next} ||= delete $opts{goto_next} if exists $opts{goto_next};

	if ( ref($function) eq 'ARRAY' ) {
		$opts{package} = $package;
		return map { signature_for( $_, %opts ) } @$function;
	}
	
	$opts{_is_signature_for} = 1;

	my $fullname = ( $function =~ /::/ ) ? $function : "$package\::$function";
	$opts{package}   ||= $package;
	$opts{subname}   ||= ( $function =~ /::(\w+)$/ ) ? $1 : $function;
	$opts{next}      ||= do { no strict 'refs'; exists(&$fullname) ? \&$fullname : undef; };
	if ( $opts{method} ) {
		$opts{next} ||= eval { $package->can( $opts{subname} ) };
	}
	if ( $opts{fallback} and not $opts{next} ) {
		$opts{next} = ref( $opts{fallback} ) ? $opts{fallback} : sub {};
	}
	if ( not $opts{next} ) {
		require Error::TypeTiny;
		return Error::TypeTiny::croak( "Function '$function' not found to wrap!" );
	}

	require Type::Params::Signature;
	my $sig = 'Type::Params::Signature'->new_from_v2api( \%opts );
	# Delay compilation
	my $compiled;
	my $coderef = sub {
		$compiled ||= $sig->coderef->compile;
		
		no strict 'refs';
		no warnings 'redefine';
		*$fullname = set_subname( $fullname, $compiled );
		
		goto( $compiled );
	};

	no strict 'refs';
	no warnings 'redefine';
	*$fullname = set_subname( $fullname, $coderef );

	return $sig;
}

sub signature_for_func {
	if ( not @_ % 2 ) {
		require Error::TypeTiny;
		Error::TypeTiny::croak( "Expected odd-sized list of arguments; did you forget the function name?" );
	}
	my ( $function, %opts ) = @_;
	my $N = !!$opts{named};
	@_ = ( $function, method => 0, allow_dash => $N, list_to_named => $N, %opts );
	goto \&signature_for;
}

sub signature_for_method {
	if ( not @_ % 2 ) {
		require Error::TypeTiny;
		Error::TypeTiny::croak( "Expected odd-sized list of arguments; did you forget the function name?" );
	}
	my ( $function, %opts ) = @_;
	my $N = !!$opts{named};
	@_ = ( $function, method => 1, allow_dash => $N, list_to_named => $N, %opts );
	goto \&signature_for;
}

sub compile {
	my @args = @_;
	@_ = ( positional => \@args );
	goto \&signature;
}

sub compile_named {
	my @args = @_;
	@_ = ( bless => 0, named => \@args );
	goto \&signature;
}

sub compile_named_oo {
	my @args = @_;
	@_ = ( bless => 1, named => \@args );
	goto \&signature;
}

# Would be faster to inline this into validate and validate_named, but
# that would complicate them. :/
sub _mk_key {
	local $_;
	join ':', map {
		Types::Standard::is_HashRef( $_ ) ? do {
			my %h = %$_;
			sprintf( '{%s}', _mk_key( map { ; $_ => $h{$_} } sort keys %h ) );
		} :
		Types::TypeTiny::is_TypeTiny( $_ ) ? sprintf( 'TYPE=%s', $_->{uniq} ) :
		Types::Standard::is_Ref( $_ )      ? sprintf( 'REF=%s', refaddr( $_ ) ) :
		Types::Standard::is_Undef( $_ )    ? sprintf( 'UNDEF' ) :
		B::perlstring( $_ )
	} @_;
} #/ sub _mk_key

{
	my %compiled;
	sub validate {
		my $arg = shift;
		my $sub = (
			$compiled{ _mk_key( @_ ) } ||= signature(
				caller_level => 1,
				%{ ref( $_[0] ) eq 'HASH' ? shift( @_ ) : +{} },
				positional => [ @_ ],
			)
		);
		@_ = @$arg;
		goto $sub;
	} #/ sub validate
}

{
	my %compiled;
	sub validate_named {
		my $arg = shift;
		my $sub = (
			$compiled{ _mk_key( @_ ) } ||= signature(
				caller_level => 1,
				bless => 0,
				%{ ref( $_[0] ) eq 'HASH' ? shift( @_ ) : +{} },
				named => [ @_ ],
			)
		);
		@_ = @$arg;
		goto $sub;
	} #/ sub validate_named
}

sub multisig {
	my %options = ( ref( $_[0] ) eq "HASH" ) ? %{ +shift } : ();
	signature(
		%options,
		multi => \@_,
	);
} #/ sub multisig

sub wrap_methods {
	my $opts = ref( $_[0] ) eq 'HASH' ? shift : {};
	$opts->{caller} ||= caller;
	$opts->{skip_invocant} = 1;
	$opts->{use_can}       = 1;
	unshift @_, $opts;
	goto \&_wrap_subs;
}

sub wrap_subs {
	my $opts = ref( $_[0] ) eq 'HASH' ? shift : {};
	$opts->{caller} ||= caller;
	$opts->{skip_invocant} = 0;
	$opts->{use_can}       = 0;
	unshift @_, $opts;
	goto \&_wrap_subs;
}

sub _wrap_subs {
	my $opts = shift;
	while ( @_ ) {
		my ( $name, $proto ) = splice @_, 0, 2;
		my $fullname = ( $name =~ /::/ ) ? $name : sprintf( '%s::%s', $opts->{caller}, $name );
		my $orig = do {
			no strict 'refs';
			exists &$fullname     ? \&$fullname
				: $opts->{use_can} ? ( $opts->{caller}->can( $name ) || sub { } )
				: sub { }
		};
		my $new;
		if ( ref $proto eq 'CODE' ) {
			$new = $opts->{skip_invocant}
				? sub {
					my $s = shift;
					@_ = ( $s, &$proto );
					goto $orig;
				}
				: sub {
					@_ = &$proto;
					goto $orig;
				};
		}
		else {
			$new = compile(
				{
					'package'   => $opts->{caller},
					'subname'   => $name,
					'next'      => $orig,
					'head'      => $opts->{skip_invocant} ? 1 : 0,
				},
				@$proto,
			);
		}
		no strict 'refs';
		no warnings 'redefine';
		*$fullname = set_subname( $fullname, $new );
	} #/ while ( @_ )
	1;
} #/ sub _wrap_subs

1;

__END__

=pod

=encoding utf-8

=for stopwords evals invocant

=head1 NAME

Type::Params - sub signature validation using Type::Tiny type constraints and coercions

=head1 SYNOPSIS

 use v5.36;
 use builtin qw( true false );
 
 package Horse {
   use Moo;
   use Types::Standard qw( Object );
   use Type::Params -sigs;
   use namespace::autoclean;
   
   ...;   # define attributes, etc
   
   signature_for add_child => (
     method     => true,
     positional => [ Object ],
   );
   
   sub add_child ( $self, $child ) {
     push $self->children->@*, $child;
     return $self;
   }
 }
 
 package main;
 
 my $boldruler = Horse->new;
 
 $boldruler->add_child( Horse->new );
 
 $boldruler->add_child( 123 );   # dies (123 is not an Object!)

=head1 STATUS

This module is covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This documents the details of the L<Type::Params> package.
L<Type::Tiny::Manual> is a better starting place if you're new.

Type::Params uses L<Type::Tiny> constraints to validate the parameters to a
sub. It takes the slightly unorthodox approach of separating validation
into two stages:

=over

=item 1.

Compiling the parameter specification into a coderef; then

=item 2.

Using the coderef to validate parameters.

=back

The first stage is slow (it might take a couple of milliseconds), but
only needs to be done the first time the sub is called. The second stage
is fast; according to my benchmarks faster even than the XS version of
L<Params::Validate>.

With the modern API, you rarely need to worry about the two stages being
internally separate.

Note that most of the examples in this documentation use modern Perl
features such as subroutine signatures, postfix dereferencing, and
the C<true> and C<false> keywords from L<builtin>. On Perl version 5.36+,
you can enable all of these features using:

 use v5.36;
 use experimental 'builtin';
 use builtin 'true', 'false';

Type::Params does support older versions of Perl (as old as 5.8), but you
may need to adjust the syntax for some examples.

=head1 MODERN API

The modern API can be exported using:

 use Type::Params -sigs;

Or:

 use Type::Params -v2;

Or by requesting functions by name:

 use Type::Params qw( signature signature_for );

Two optional shortcuts can be exported:

 use Type::Params qw( signature_for_func signature_for_method );

Or:

 use Type::Params -sigplus;

=head2 C<< signature_for $function_name => ( %spec ) >>

Wraps an existing function in additional code that implements all aspects
of the subroutine's signature, including unpacking arguments from C<< @_ >>,
applying default values, coercing, and validating values.

C<< signature_for( \@functions, %opts ) >> is a useful shortcut if you have
multiple functions with the same signature.

 signature_for [ 'add_nums', 'subtract_nums' ] => (
   positional => [ Num, Num ],
 );

Although normally used in void context, C<signature_for> does return a value.

 my $meta = signature_for add_nums => (
   positional => [ Num, Num ],
 );
 
 sub add_nums ( $x, $y ) {
   return $x + $y;
 }

Or when used with multiple functions:

 my @metas = signature_for [ 'add_nums', 'subtract_nums' ] => (...);

This is a blessed L<Type::Params::Signature> object which provides some
introspection possibilities. Inspecting C<< $meta->coderef->code >> can
be useful to see what the signature is doing internally.

=head3 Signature Specification Options

The signature specification is a hash which must contain either a
C<positional>, C<named>, or C<multiple> key indicating whether your
function takes positional parameters, named parameters, or supports
multiple calling conventions, but may also include other options.

=head4 C<< positional >> B<ArrayRef>

This is conceptually a list of type constraints, one for each positional
parameter. For example, a signature for a function which accepts two
integers:

 signature_for myfunc => ( positional => [ Int, Int ] );

However, each type constraint is optionally followed by a hashref of
options which affect that parameter. For example:

 signature_for myfunc => ( positional => [
   Int, { default => 40 },
   Int, { default =>  2 },
 ] );

Type constraints can instead be given as strings, which will be looked
up using C<dwim_type> from L<Type::Utils>.

 signature_for myfunc => ( positional => [
   'Int', { default => 40 },
   'Int', { default =>  2 },
 ] );

See the section below for more information on parameter options.

Optional parameters must follow required parameters, and can be specified
using either the B<Optional> parameterizable type constraint, the
C<optional> parameter option, or by providing a default.

 # All three parameters are effectively optional.
 signature_for myfunc => ( positional => [
   Optional[Int],
   Int, { optional => true },
   Int, { default  => 42 },
 ] );

A single slurpy parameter may be provided at the end, using the B<Slurpy>
parameterizable type constraint, or the C<slurpy> parameter option:

 signature_for myfunc => ( positional => [
   Int,
   Slurpy[ ArrayRef[Int] ],
 ] );

 signature_for myfunc => ( positional => [
   Int,
   ArrayRef[Int], { slurpy => true },
 ] );

The C<positional> option can also be abbreviated to C<pos>.

So C<< signature_for myfunc => ( pos => [...] ) >> can be used instead of
the longer C<< signature_for myfunc => ( positional => [...] ) >>.

 signature_for add_numbers => ( pos => [ Num, Num ] );
 
 sub add_numbers ( $num1, $num2 ) {
   return $num1 + $num2;
 }
 
 say add_numbers( 2, 3 );   # says 5

=head4 C<< named >> B<ArrayRef>

This is conceptually a list of pairs of names and type constraints, one
name+type pair for each named parameter. For example, a signature for
a function which accepts two integers:

 signature_for myfunc => ( named => [ foo => Int, bar => Int ] )

However, each type constraint is optionally followed by a hashref of
options which affect that parameter. For example:

 signature_for myfunc => ( named => [
   foo => Int, { default => 40 },
   bar => Int, { default =>  2 },
 ] );

Type constraints can instead be given as strings, which will be looked
up using C<dwim_type> from L<Type::Utils>.

 signature_for myfunc => ( named => [
   foo => 'Int', { default => 40 },
   bar => 'Int', { default =>  2 },
 ] );

Optional and slurpy parameters are allowed, but unlike positional parameters,
they do not need to be at the end.

See the section below for more information on parameter options.

If a signature uses named parameters, the values are supplied to the
function as a single parameter object:

 signature_for add_numbers => ( named => [ num1 => Num, num2 => Num ] );
 
 sub add_numbers ( $arg ) {
   return $arg->num1 + $arg->num2;
 }
 
 say add_numbers(   num1 => 2, num2 => 3   );   # says 5
 say add_numbers( { num1 => 2, num2 => 3 } );   # also says 5

=head4 C<< named_to_list >> B<< ArrayRef|Bool >>

The C<named_to_list> option is ignored for signatures using positional
parameters, but for signatures using named parameters, allows them to
be supplied to the function as a list of values instead of as a single
object:

 signature_for add_numbers => (
   named         => [ num1 => Num, num2 => Num ],
   named_to_list => true,
 );
 
 sub add_numbers ( $num1, $num2 ) {
   return $num1 + $num2;
 }
 
 say add_numbers(   num1 => 2, num2 => 3   );   # says 5
 say add_numbers( { num1 => 2, num2 => 3 } );   # also says 5

You can think of C<add_numbers> above as a function which takes named
parameters from the outside, but receives positional parameters on the
inside.

You can use an arrayref to control the order in which the parameters will
be supplied. (By default they are returned in the order in which they were
defined.)

 signature_for add_numbers => (
   named         => [ num1 => Num, num2 => Num ],
   named_to_list => [ qw( num2 num1 ) ],
 );
 
 sub add_numbers ( $num2, $num1 ) {
   return $num1 + $num2;
 }
 
 say add_numbers(   num1 => 2, num2 => 3   );   # says 5
 say add_numbers( { num1 => 2, num2 => 3 } );   # also says 5

=head4 C<< list_to_named >> B<< Bool >>

For a function that accepts named parameters, allows them to alternatively
be supplied as a list in a hopefully do-what-you-mean manner.

 signature_for add_numbers => (
   named         => [ num1 => Num, num2 => Num ],
   list_to_named => true,
 );
 
 sub add_numbers ( $arg ) {
   return $arg->num1 + $arg->num2;
 }
 
 say add_numbers( num1 => 5, num2 => 10 );      # says 15
 say add_numbers( { num1 => 5, num2 => 10 } );  # also says 15
 say add_numbers( 5, num2 => 10 );              # says 15 yet again
 say add_numbers( 5, { num2 => 10 } );          # guess what? says 15
 say add_numbers( 10, num1 => 5 );              # 14. just kidding! 15
 say add_numbers( 10, { num1 => 5 } );          # another 15
 say add_numbers( 5, 10 );                      # surprise, it says 15
 
 # BAD: list_to_named argument cannot be at the end.
 say add_numbers( { num1 => 5 }, 10 );
 
 # BAD: list_to_named argument duplicated.
 say add_numbers( 5, 10, { num1 => 5 } );

Where a hash or hashref of named parameters are expected, any parameter
which doesn't look like it fits that pattern will be treated as a "sneaky"
positional parameter, and will be tried the first time a named parameter
seems to be missing.

This feature is normally only applied to required parameters. It can be
manually controlled on a per-parameter basis using the C<in_list> option.

Type::Params attempts to be intelligent at figuring out what order
the sneaky positional parameters were given in.

 signature_for add_to_ref => (
   named         => [ ref => ScalarRef[Num], add => Num ],
   list_to_named => true,
 );
 
 sub add_to_ref ( $arg ) {
   $arg->ref->$* += $arg->num;
 }
 
 my $sum = 0;
 add_to_ref( ref => \$sum, add => 1 );
 add_to_ref( \$sum, add => 2 );
 add_to_ref( \$sum, 3 );
 add_to_ref( 4, \$sum );
 add_to_ref( 5, sum => \$sum );
 add_to_ref( add => 5, sum => \$sum );
 say $sum; # 21

This approach is somewhat slower, but has the potential for very
do-what-I-mean functions.

Note that C<list_to_named> and C<named_to_list> can both be used in
the same signature as their meanings are not contradictory.

 signature_for add_to_ref => (
   named         => [ ref => ScalarRef[Num], add => Num ],
   list_to_named => true,
   named_to_list => true,
 );
 
 sub add_to_ref ( $ref, $num ) {
   $ref->$* += $num;
 }

=head4 C<< head >> B<< Int|ArrayRef >>

C<head> provides an additional list of non-optional, positional parameters
at the start of C<< @_ >>. This is often used for method calls. For example,
if you wish to define a signature for:

 $object->my_method( foo => 123, bar => 456 );

You could write it as this:

 signature_for my_method => (
   head    => [ Object ],
   named   => [ foo => Optional[Int], bar => Optional[Int] ],
 );
 
 sub my_method ( $self, $arg ) {
   ...;
 }

If C<head> is set as a number instead of an arrayref, it is the number of
additional arguments at the start:

 signature_for stash_foobar = (
   head    => 2,
   named   => [ foo => Optional[Int], bar => Optional[Int] ],
 );
 
 sub stash_foobar ( $self, $ctx, $arg ) {
   $ctx->stash->{foo} = $arg->foo if $arg->has_foo;
   $ctx->stash->{bar} = $arg->bar if $arg->has_bar;
   return $self;
 }
 
 ...;
 
 $app->stash_foobar( $context, foo => 123 );

In this case, no type checking is performed on those additional arguments;
it is just checked that they exist.

=head4 C<< tail >> B<< Int|ArrayRef >>

A C<tail> is like a C<head> except that it is for arguments at the I<end>
of C<< @_ >>.

 signature_for my_method => (
   head    => [ Object ],
   named   => [ foo => Optional[Int], bar => Optional[Int] ],
   tail    => [ CodeRef ],
 );
 
 sub my_method ( $self, $arg, $callback ) {
   ...;
 }
 
 $object->my_method( foo => 123, bar => 456, sub { ... } );

=head4 C<< method >> B<< Bool|TypeTiny >>

While C<head> can be used for method signatures, a more declarative way is
to set C<< method => true >>.

If you wish to be specific that this is an object method, intended to be
called on blessed objects only, then you may use C<< method => Object >>,
using the B<Object> type from L<Types::Standard>. If you wish to specify
that it's a class method, then use C<< method => Str >>, using the B<Str>
type from L<Types::Standard>. (C<< method => ClassName >> is perhaps
clearer, but it's a slower check.)

 signature_for my_method => (
   method  => true,
   named   => [ foo => Optional[Int], bar => Optional[Int] ],
 );
 
 sub my_method ( $self, $arg ) {
   ...;
 }

The C<method> option has some other subtle differences from C<head>. Any
parameter defaults which are coderefs will be called as methods on the
invocant instead of being called with no arguments. The C<package> option
will be interpreted slightly differently.

It is possible to use both C<method> and C<head> in the same signature.
The invocant is interpreted as being I<before> the C<head>.

A shortcut is provided for C<< method => true >>, though it also enables
a couple of other options.

 use Type::Params qw( signature_for_method );
 
 signature_for_method my_method => (
   named => [ foo => Optional[Int], bar => Optional[Int] ],
 );
 
 sub my_method ( $self, $arg ) {
   ...;
 }

=head4 C<< description >> B<Str>

This is the description of the coderef that will show up in stack traces.
It defaults to "parameter validation for X" where X is the sub name. Usually
the default will be fine.

=head4 C<< package >> B<Str>

This allows you to add signatures to functions in other packages:

 signature_for foo => ( package "Some::Package", ... );

If C<method> is true and Some::Package doesn't contain a sub called "foo",
then Type::Params will traverse the inheritance heirarchy, looking for "foo".

If any type constraints are specified as strings, Type::Params will look
for types imported by this package.

 # Expects the MyInt type to be known by Some::Package.
 signature_for foo => ( package "Some::Package", pos => [ 'MyInt' ] );

This is also supported:

 signature_for "Some::Package::foo" => ( ... );

=head4 C<< fallback >> B<CodeRef|Bool>

If the sub being wrapped cannot be found, then C<signature_for> will usually
throw an error. If you want it to "still work" in this situation, use the
C<fallback> option. C<< fallback => \&alternative_coderef_to_wrap >>
will instead wrap a different coderef if the original cannot be found.
C<< fallback => true >> is a shortcut for C<< fallback => sub {} >>.
An example where this might be useful is if you're adding signatures to
methods which are inherited from a parent class, but you are not 100%
confident will exist (perhaps dependent on the version of the parent class).

 signature_for add_nums => (
   positional => [ Num, Num ],
   fallback   => sub { $_[0] + $_[1] },
 );

=head4 C<< on_die >> B<< Maybe[CodeRef] >>

Usually when the signature check hits an error, it will throw an exception,
which is a blessed L<Error::TypeTiny> object.

If you provide an C<on_die> coderef, then instead the L<Error::TypeTiny>
object will be passed to it.

 signature_for add_numbers => (
   positional => [ Num, Num ],
   on_die     => sub {
     my $error = shift;
     print "Existential crisis: $error\n";
     exit( 1 );
   },
 );
 
 sub add_numbers ( $num1, $num2 ) {
   return $num1 + $num2;
 }
 
 say add_numbers();   # has an existential crisis

If your C<on_die> coderef doesn't exit or throw an exception, it can
instead return a list which will be used as parameters for your function.

 signature_for add_numbers => (
   positional => [ Num, Num ],
   on_die     => sub { return ( 40, 2 ) },
 );
 
 sub add_numbers ( $num1, $num2 ) {
   return $num1 + $num2;
 }
 
 say add_numbers();   # 42

This is probably not very useful.

=head4 C<< strictness >> B<< Bool|Str >>

If you set C<strictness> to false, then certain signature checks will simply
never be done. The initial check that there's the correct number of parameters,
plus type checks on parameters which don't coerce can be skipped.

If you set it to true or do not set it at all, then these checks will always
be done.

Alternatively, it may be set to the quoted fully-qualified name of a Perl
global variable or a constant, and that will be compiled into the coderef
as a condition to enable strict checks.

 signature_for my_func => (
   strictness => '$::CHECK_TYPES',
   positional => [ Int, ArrayRef ],
 );
 
 sub my_func ( $int, $aref ) {
   ...;
 }
 
 # Type checks are skipped
 {
   local $::CHECK_TYPES = false;
   my ( $number, $list ) = my_func( {}, {} );
 }
 
 # Type checks are performed
 {
   local $::CHECK_TYPES = true;
   my ( $number, $list ) = my_func( {}, {} );
 }

A recommended use of C<strictness> is with L<Devel::StrictMode>.

 use Devel::StrictMode qw( STRICT );
 
 state $signature = signature(
   strictness => STRICT,
   positional => [ Int, ArrayRef ],
 );

=head4 C<< multiple >> B<< ArrayRef|HashRef >>

This option allows your signature to support multiple calling conventions.
Each entry in the array is an alternative signature, as a hashref:

 signature_for my_func => (
   multiple => [
     {
       positional    => [ ArrayRef, Int ],
     },
     {
       named         => [ array => ArrayRef, index => Int ],
       named_to_list => true,
     },
   ],
 );
 
 sub my_func ( $aref, $int ) {
   ...;
 }

That signature will allow your function to be called as:

 your_function( $arr, $ix );
 your_function( array => $arr, index => $ix );
 your_function( { array => $arr, index => $ix } );

Sometimes the alternatives will return the parameters in different orders:

 signature_for my_func => (
   multiple => [
     { positional => [ ArrayRef, Int ] },
     { positional => [ Int, ArrayRef ] },
   ],
 );

So how does your sub know how it's been called? One option is to use the
C<< ${^_TYPE_PARAMS_MULTISIG} >> global variable which will be set to the
index of the signature which was used:

 sub my_func {
   my ( $arr, $ix ) = ${^_TYPE_PARAMS_MULTISIG} == 1 ? reverse( @_ ) : @_;
   ...;
 }

If you'd prefer to use identifying names instead of a numeric index, you
can specify these using C<ID>:

 signature_for my_func => (
   multiple => [
     { ID => 'one', positional => [ ArrayRef, Int ] },
     { ID => 'two', positional => [ Int, ArrayRef ] },
   ],
 );

Or by using a hashref:

 signature_for my_func => (
   multiple => {
     one => { positional => [ ArrayRef, Int ] },
     two => { positional => [ Int, ArrayRef ] },
   },
 );

A neater solution is to use a C<next> coderef to re-order alternative
signature results into your preferred order:

 signature_for my_func => (
   multiple => [
     { positional => [ ArrayRef, Int ] },
     { positional => [ Int, ArrayRef ], next => sub { reverse @_ } },
   ],
 );
 
 sub my_func ( $arr, $ix ) {
   ...;
 }

While conceptally C<multiple> is an arrayref of hashrefs, it is also possible
to use arrayrefs in the arrayref.

 multiple => [
   [ ArrayRef, Int ],
   [ Int, ArrayRef ],
 ]

When an arrayref is used like that, it is a shortcut for a positional
signature.

Coderefs may additionally be used:

 signature_for my_func => (
   multiple => [
     [ ArrayRef, Int ],
     { positional => [ Int, ArrayRef ], next => sub { reverse @_ } },
     sub { ... },
     sub { ... },
   ],
 );

The coderefs should be subs which return a list of parameters if they
succeed and throw an exception if they fail.

The following signatures are equivalent:

 signature_for my_func => (
   multiple => [
     { method => true, positional => [ ArrayRef, Int ] },
     { method => true, positional => [ Int, ArrayRef ] },
   ],
 );
 
 signature_for my_func => (
   method   => true,
   multiple => [
     { positional => [ ArrayRef, Int ] },
     { positional => [ Int, ArrayRef ] },
   ],
 );

The C<multiple> option can also be abbreviated to C<multi>.
So C<< signature( multi => [...] ) >> can be used instead of the longer
C<< signature( multiple => [...] ) >>. Three whole keystrokes saved!

(B<Note:> in older releases of Type::Params, C<< ${^_TYPE_PARAMS_MULTISIG} >>
was called C<< ${^TYPE_PARAMS_MULTISIG} >>. The latter name is no longer
supported.)

=head4 C<< message >> B<Str>

Only used by C<multiple> signatures. The error message to throw when no
signatures match.

=head4 C<< bless >> B<Bool|ClassName>, C<< class >> B<< ClassName|ArrayRef >>, and C<< constructor >> B<Str>

Named parameters are usually returned as a blessed object:

 signature_for add_numbers => ( named => [ num1 => Num, num2 => Num ] );
 
 sub add_numbers ( $arg ) {
   return $arg->num1 + $arg->num2;
 }

The class they are blessed into is one built on-the-fly by Type::Params.
However, these three signature options allow you more control over that
process.

Firstly, if you set C<< bless => false >> and do not set C<class> or
C<constructor>, then C<< $arg >> will just be an unblessed hashref.

 signature_for add_numbers => (
   named        => [ num1 => Num, num2 => Num ],
   bless        => false,
 );
 
 sub add_numbers ( $arg ) {
   return $arg->{num1} + $arg->{num2};
 }

This is a good speed boost, but having proper methods for each named
parameter is a helpful way to catch misspelled names.

If you wish to manually create a class instead of relying on Type::Params
generating one on-the-fly, you can do this:

 package Params::For::AddNumbers {
   sub num1 ( $self ) {
     return $self->{num1};
   }
   sub num2 ( $self ) {
     return $self->{num2};
   }
   sub sum ( $self ) {
     return $self->num1 + $self->num2;
   }
 }
 
 signature_for add_numbers => (
   named        => [ num1 => Num, num2 => Num ],
   bless        => 'Params::For::AddNumbers',
 );
 
 sub add_numbers ( $arg ) {
   return $arg->sum;
 }

Note that C<Params::For::AddNumbers> here doesn't include a C<new> method
because Type::Params will directly do C<< bless( $arg, $opts{bless} ) >>.

If you want Type::Params to use a proper constructor, you should use the
C<class> option instead:

 package Params::For::AddNumbers {
   use Moo;
   has [ 'num1', 'num2' ] => ( is => 'ro' );
   sub sum {
     my $self = shift;
     return $self->num1 + $self->num2;
   }
 }
 
 signature_for add_numbers => (
   named        => [ num1 => Num, num2 => Num ],
   class        => 'Params::For::AddNumbers',
 );
 
 sub add_numbers ( $arg ) {
   return $arg->sum;
 }

If you wish to use a constructor named something other than C<new>, then
use:

 signature_for add_numbers => (
   named        => [ num1 => Num, num2 => Num ],
   class        => 'Params::For::AddNumbers',
   constructor  => 'new_from_hashref',
 );

Or as a shortcut:

 signature_for add_numbers => (
   named        => [ num1 => Num, num2 => Num ],
   class        => [ 'Params::For::AddNumbers' => 'new_from_hashref' ],
 );

It is doubtful you want to use any of these options, except
C<< bless => false >>.

=head4 C<< returns >> B<TypeTiny>, C<< returns_scalar >> B<TypeTiny>, and C<< returns_list >> B<TypeTiny>

These can be used to specify the type returned by your function.

 signature_for round_number => (
   pos          => [ Num ],
   returns      => Int,
 );
 
 sub round_number ( $num ) {
   return int( $num );
 }

If your function returns different types in scalar and list context,
you can use C<returns_scalar> and C<returns_list> to indicate separate
return types in different contexts.

 signature_for my_func => (
   pos             => [ Int, Int ],
   returns_scalar  => Int,
   returns_list    => Tuple[ Int, Int, Int ],
 );

The C<returns_list> constraint is defined using an B<ArrayRef>-like or
B<HashRef>-like type constraint even though it's returning a list, not
a single reference.

If your function is called in void context, then its return value is
unimportant and should not be type checked.

=head4 C<< allow_dash >> B<Bool>

For any "word-like" named parameters or aliases, automatically creates an
alias with a leading hyphen.

 signature_for withdraw_funds => (
   named      => [ amount => Num, account => Str ],
   allow_dash => true,
 );
 
 sub withdraw_funds ( $arg ) {
   ...;
 }
 
 withdraw_funds(  amount => 11.99,  account => 'ABC123' );
 withdraw_funds( -amount => 11.99,  account => 'ABC123' );
 withdraw_funds(  amount => 11.99, -account => 'ABC123' );
 withdraw_funds( -amount => 11.99, -account => 'ABC123' );

Has no effect on names that are not word-like. Word-like names are those
matching C<< /\A[^\W0-9]\w*\z/ >>; essentially anything Perl allows as a
normal unqualified variable name.

=head3 Parameter Options

In the parameter lists for the C<positional> and C<named> signature
options, each parameter may be followed by a hashref of options specific
to that parameter:

 signature_for my_func => (
   positional => [
     Int, \%options_for_first_parameter,
     Int, \%options_for_other_parameter,
   ],
   %more_options_for_signature,
 );

 signature_for my_func => (
   named => [
     foo => Int, \%options_for_foo,
     bar => Int, \%options_for_bar,
   ],
   %more_options_for_signature,
 );

The following options are supported for parameters.

=head4 C<< optional >> B<Bool>

An option I<called> optional!

This makes a parameter optional:

 signature_for add_nums => (
   positional => [
     Int,
     Int,
     Bool, { optional => true },
   ],
 );
 
 sub add_nums ( $num1, $num2, $debug ) {
   my $sum = $num1 + $num2;
   warn "$sum = $num1 + $num2" if $debug;
   return $sum;
 }
 
 add_nums( 2, 3, 1 );   # prints warning
 add_nums( 2, 3, 0 );   # no warning
 add_nums( 2, 3    );   # no warning

L<Types::Standard> also provides a B<Optional> parameterizable type
which may be a neater way to do this:

 signature_for add_nums => ( pos => [ Int, Int, Optional[Bool] ] );

In signatures with positional parameters, any optional parameters must be
defined I<after> non-optional parameters. The C<tail> option provides a
workaround for required parameters at the end of C<< @_ >>.

In signatures with named parameters, the order of optional and non-optional
parameters is unimportant.

=head4 C<< slurpy >> B<Bool>

A signature may contain a single slurpy parameter, which mops up any other
arguments the caller provides your function.

In signatures with positional parameters, slurpy params must always have
some kind of B<ArrayRef> or B<HashRef> type constraint, must always appear
at the I<end> of the list of positional parameters, and they work like this:

 signature_for add_nums => (
   positional => [
     Num,
     ArrayRef[Num], { slurpy => true },
   ],
 );
 
 sub add_nums ( $first_num, $other_nums ) {
   my $sum = $first_num;
   for my $other ( $other_nums->@* ) {
     $sum += $other;
   }
   return $sum;
 }
 
 say add_nums( 1 );            # says 1
 say add_nums( 1, 2 );         # says 3
 say add_nums( 1, 2, 3 );      # says 6
 say add_nums( 1, 2, 3, 4 );   # says 10

In signatures with named parameters, slurpy params must always have
some kind of B<HashRef> type constraint, and they work like this:

 use builtin qw( true false );
 
 signature_for process_data => (
   method => true,
   named  => [
     input   => FileHandle,
     output  => FileHandle,
     flags   => HashRef[Bool], { slurpy => true },
   ],
 );
 
 sub process_data ( $self, $arg ) {
   warn "Beginning data processing" if $arg->flags->{debug};
   ...;
 }
 
 $widget->process_data(
   input  => \*STDIN,
   output => \*STDOUT,
   debug  => true,
 );

The B<Slurpy> type constraint from L<Types::Standard> may be used as
a shortcut to specify slurpy parameters:

 signature_for add_nums => (
   positional => [ Num, Slurpy[ ArrayRef[Num] ] ],
 )

The type B<< Slurpy[Any] >> is handled specially and treated as a
slurpy B<ArrayRef> in signatures with positional parameters, and a
slurpy B<HashRef> in signatures with named parameters, but has some
additional optimizations for speed.

=head4 C<< default >> B<< CodeRef|ScalarRef|Ref|Str|Undef >>

A default may be provided for a parameter.

 signature_for my_func => (
   positional => [
     Int,
     Int, { default => "666" },
     Int, { default => "999" },
   ],
 );

Supported defaults are any strings (including numerical ones), C<undef>,
and empty hashrefs and arrayrefs. Non-empty hashrefs and arrayrefs are
I<< not allowed as defaults >>.

Alternatively, you may provide a coderef to generate a default value:

 signature_for my_func => (
   positional => [
     Int,
     Int, { default => sub { 6 * 111 } },
     Int, { default => sub { 9 * 111 } },
   ]
 );

That coderef may generate any value, including non-empty arrayrefs and
non-empty hashrefs. For undef, simple strings, numbers, and empty
structures, avoiding using a coderef will make your parameter processing
faster.

Instead of a coderef, you can use a reference to a string of Perl source
code:

 signature_for my_func => (
   positional => [
     Int,
     Int, { default => \ '6 * 111' },
     Int, { default => \ '9 * 111' },
   ],
 );

Defaults I<will> be validated against the type constraint, and
potentially coerced.

Any parameter with a default will automatically be optional, as it
makes no sense to provide a default for required paramaters.

Note that having I<any> defaults in a signature (even if they never
end up getting used) can slow it down, as Type::Params will need to
build a new array instead of just returning C<< @_ >>.

=head4 C<< default_on_undef >> B<Bool>

Normally defaults are only applied when a parameter is I<missing> (think
C<exists> for hashes or the array being too short). Setting
C<default_on_undef> to true will also trigger the default if a parameter
is provided but undefined.

If the caller might legitimately want to supply undef as a value, it is
not recommended you uswe this.

=head4 C<< coerce >> B<Bool>

Speaking of coercion, the C<coerce> option allows you to indicate that a
value should be coerced into the correct type:

 signature_for my_func => (
   positional => [
     Int,
     Int,
     Bool, { coerce => true },
   ],
 );

Setting C<coerce> to false will disable coercion.

If C<coerce> is not specified, so is neither true nor false, then
coercion will be enabled if the type constraint has a coercion, and
disabled otherwise.

Note that having I<any> coercions in a signature (even if they never
end up getting used) can slow it down, as Type::Params will need to
build a new array instead of just returning C<< @_ >>.

=head4 C<< clone >> B<Bool>

If this is set to true, it will deep clone incoming values via C<dclone>
from L<Storable> (a core module since Perl 5.7.3).

In the below example, C<< $arr >> is a reference to a I<clone of>
C<< @numbers >>, so pushing additional numbers to it leaves C<< @numbers >>
unaffected.

 signature_for foo => (
   positional => [ ArrayRef, { clone => true } ],
 );
 
 sub foo ( $arr ) {
   push @$arr, 4, 5, 6;
 }
 
 my @numbers = ( 1, 2, 3 );
 foo( \@numbers );
 print "@numbers\n";  ## 1 2 3

Note that cloning will significantly slow down your signature.

=head4 C<< name >> B<Str>

This overrides the name of a named parameter. I don't know why you
would want to do that.

The following signature has two parameters: C<foo> and C<bar>. The
name C<fool> is completely ignored.

 signature_for my_func => (
   named => [
     fool   => Int, { name => 'foo' },
     bar    => Int,
   ],
 );

You can, however, also name positional parameters, which don't usually
have names.

 signature_for my_func => (
   positional => [
     Int, { name => 'foo' },
     Int, { name => 'bar' },
   ],
 );

The names of positional parameters are not really I<used> for anything
at the moment, but may be incorporated into error messages or
similar in the future.

=head4 C<< getter >> B<Str>

For signatures with named parameters, specifies the method name used
to retrieve this parameter's value from the C<< $arg >> object.

 signature_for process_data => (
   method => true,
   named  => [
     input   => FileHandle,    { getter => 'in' },
     output  => FileHandle,    { getter => 'out' },
     flags   => HashRef[Bool], { slurpy => true },
   ],
 );
 
 sub process_data ( $self, $arg ) {
   warn "Beginning data processing" if $arg->flags->{debug};
   
   my ( $in, $out ) = ( $arg->in, $arg->out );
   ...;
 }
 
 $widget->process_data(
   input  => \*STDIN,
   output => \*STDOUT,
   debug  => true,
 );

Ignored by signatures with positional parameters.

=head4 C<< predicate >> B<Str>

The C<< $arg >> object provided by signatures with named parameters
will also include "has" methods for any optional arguments.
For example:

 signature_for process_data => (
   method => true,
   named  => [
     input   => Optional[ FileHandle ],
     output  => Optional[ FileHandle ],
     flags   => Slurpy[ HashRef[Bool] ],
   ],
 );
 
 sub process_data ( $self, $arg ) {
   
   if ( $self->has_input and $self->has_output ) {
     ...;
   }
   
   ...;
 }

Setting a C<predicate> option allows you to choose a different name
for this method instead of "has_*".

It is also possible to set a C<predicate> for non-optional parameters,
which don't normally get a "has" method.

Ignored by signatures with positional parameters.

=head4 C<< alias >> B<< Str|ArrayRef[Str] >>

A list of alternative names for the parameter, or a single alternative
name.

 signature_for add_numbers => (
   named => [
     first_number   => Int, { alias => [ 'x' ] },
     second_number  => Int, { alias =>   'y'   },
   ],
 );
 
 sub add_numbers ( $arg ) {
   return $arg->first_number + $arg->second_number;
 }
 
 say add_numbers( first_number => 40, second_number => 2 );  # 42
 say add_numbers( x            => 40, y             => 2 );  # 42
 say add_numbers( first_number => 40, y             => 2 );  # 42
 say add_numbers( first_number => 40, x => 1, y => 2 );      # dies!

Ignored by signatures with positional parameters.

=head4 C<< in_list >> B<Bool>

In conjunction with C<list_to_named>, determines if this parameter can
be provided as part of the list of "sneaky" positional parameters.
If C<list_to_named> isn't being used, C<in_list> is ignored.

Defaults to false if the parameter is optional or has a default.
Defaults to true if the parameter is required.

=head4 C<< strictness >> B<Bool|Str>

Overrides the signature option C<strictness> on a per-parameter basis.

=head2 C<< signature_for_func $function_name => ( %spec ) >>

Like C<signature_for> and defaults to C<< method => false >>.

If the signature has named parameters, it will additionally default
C<list_to_named> and C<allow_dash> to true.

 signature_for_func add_to_ref => (
   named         => [ ref => ScalarRef[Num], add => Num ],
   named_to_list => true,
 );
 
 sub add_to_ref ( $ref, $add ) {
   $ref->$* += $add;
 }
 
 my $sum = 0;
 add_to_ref( ref => \$sum, add => 1 );
 add_to_ref( \$sum, 2 );
 add_to_ref( 3, \$sum );
 add_to_ref( 4, { -ref => \$sum } );
 say $sum; # 10

The exact behaviour of C<signature_for_func> is unstable and may change
in future versions of Type::Params.

=head2 C<< signature_for_method $function_name => ( %spec ) >>

Like C<signature_for> but will default C<< method => true >>.

If the signature has named parameters, it will additionally default
C<list_to_named> and C<allow_dash> to true.

 package Calculator {
   use Types::Standard qw( Num ScalarRef );
   use Type::Params qw( signature_for_method );
   
   ...;
   
   signature_for_method add_to_ref => (
     named         => [ ref => ScalarRef[Num], add => Num ],
     named_to_list => true,
   );
   
   sub add_to_ref ( $self, $ref, $add ) {
     $ref->$* += $add;
   }
 }
 
 my $calc = Calculator->new;
 my $sum = 0;
 $calc->add_to_ref( ref => \$sum, add => 1 );
 $calc->add_to_ref( \$sum, 2 );
 $calc->add_to_ref( 3, \$sum );
 $calc->add_to_ref( 4, { -ref => \$sum } );
 say $sum; # 10

The exact behaviour of C<signature_for_method> is unstable and may change
in future versions of Type::Params.

=head2 C<< signature( %spec ) >>

The C<signature> function allows more fine-grained control over signatures.
Instead of automatically wrapping your function, it returns a coderef that
you can pass C<< @_ >> to.

The following are roughly equivalent:

 signature_for add_nums => ( pos => [ Num, Num ] );
 
 sub add_nums ( $x, $y ) {
   return $x + $y;
 }

And:

 sub add_nums {
   state $signature = signature( pos => [ Num, Num ] );
   my ( $x, $y ) = $signature->( @_ );
   
   return $x + $y;
 }

Perl allows a slightly archaic way of calling coderefs without using
parentheses, which may be slightly faster at the cost of being more
obscure:

 sub add_nums {
   state $signature = signature( pos => [ Num, Num ] );
   my ( $x, $y ) = &$signature; # important: no parentheses!
   
   return $x + $y;
 }

If you need to support Perl 5.8, which didn't have the C<state> keyword:

 my $__add_nums_sig;
 sub add_nums {
   $__add_nums_sig ||= signature( pos => [ Num, Num ] );
   my ( $x, $y ) = &$__add_nums_sig;
   
   ...;
 }

This gives you more control over how and when the signature is built and
used, and what is done with the values it unpacks.

In particular, note that if your function is never called, the signature
never even gets built, meaning that for functions you rarely use, there's
less cost to having the signature.

As of 2025, you probably want to be using C<signature_for> instead of
C<signature> in most cases.

=head3 Additional Signature Specification Options

There are certain options which make no sense for C<signature_for>, and
are only useful for C<signature>. Others may behave slightly differently.
These are noted here.

=head4 C<< returns >> B<TypeTiny>, C<< returns_scalar >> B<TypeTiny>, and C<< returns_list >> B<TypeTiny>

Because C<signature> isn't capable of fully wrapping your function,
the C<returns>, C<returns_scalar>, and C<returns_list> options cannot
do anything. You should consider them to be documentation only.

=head4 C<< subname >> B<Str>

The name of the sub whose parameters we're supposed to be checking.
This is useful in stack traces, etc. Defaults to the caller.

=head4 C<< package >> B<Str>

Works the same as in C<signature_for>, but it's worth mentioning it
again as it ties in closely with C<subname>.

=head4 C<< caller_level >> B<Int>

If you're wrapping C<signature> so that you can check signatures on behalf
of another package, then setting C<caller_level> to 1 (or more, depending on
the level of wrapping!) may be an alternative to manually setting the
C<package> and C<subname>.

=head4 C<< next >> B<< Bool|CodeLike >>

This can be used for chaining coderefs. If you understand C<on_die>, this
acts like an "on_live".

 sub add_numbers {
   state $sig = signature(
     positional => [ Num, Num ],
     next => sub {
       my ( $num1, $num2 ) = @_;
       
       return $num1 + $num2;
     },
   );
   
   my $sum = $sig->( @_ );
   return $sum;
 }
 
 say add_numbers( 2, 3 );   # says 5

If set to true instead of a coderef, has a slightly different behaviour:

 sub add_numbers {
   state $sig = signature(
     positional => [ Num, Num ],
     next       => true,
   );
   
   my $sum = $sig->(
     sub { return $_[0] + $_[1] },
     @_,
   );
   return $sum;
 }
 
 say add_numbers( 2, 3 );   # says 5

This looks strange. Why would this be useful? Well, it works nicely with
Moose's C<around> keyword.

 sub add_numbers {
   return $_[1] + $_[2];
 }
 
 around add_numbers => signature(
   method     => true,
   positional => [ Num, Num ],
   next       => true,
   package    => __PACKAGE__,
   subname    => 'add_numbers',
 );
 
 say __PACKAGE__->add_numbers( 2, 3 );   # says 5

Note the way C<around> works in Moose is that it expects a wrapper coderef
as its final argument. That wrapper coderef then expects to be given a
reference to the original function as its first parameter.

This can allow, for example, a role to provide a signature wrapping
a method defined in a class.

This is kind of complex, and you're unlikely to use it, but it's been proven
useful for tools that integrate Type::Params with Moose-like method modifiers.

Note that C<next> is the mechanism that C<signature_for> internally
uses to connect the signature with the wrapped sub, so using C<next>
with C<signature_for> is a good recipe for headaches.

If using C<multiple> signatures, C<next> is useful for each "inner"
signature to massage parameters into the correct order. This use of
C<next> I<is> supported for C<signature_for>.

The option C<goto_next> is supported as a historical alias for C<next>.

=head4 C<< want_source >> B<Bool>

Instead of returning a coderef, return Perl source code string. Handy
for debugging.

=head4 C<< want_details >> B<Bool>

Instead of returning a coderef, return a hashref of stuff including the
coderef. This is mostly for people extending Type::Params and I won't go
into too many details about what else this hashref contains.

=head4 C<< want_object >> B<Bool>

Instead of returning a coderef, return a Type::Params::Signature object.
This is the more modern version of C<want_details>.

=head1 LEGACY API

The following functions were the API prior to Type::Params v2. They are
still supported, but their use is now discouraged.

If you don't provide an import list at all, you will import C<compile>
and C<compile_named>:

 use Type::Params;

This does the same:

  use Type::Params -v1;

The following exports C<compile>, C<compile_named>, and C<compile_named_oo>:

 use Type::Params -compile;

The following exports C<wrap_subs> and C<wrap_methods>:

 use Type::Params -wrap;

=head2 C<< compile( @pos_params ) >>

Equivalent to C<< signature( positional => \@pos_params ) >>.

C<< compile( \%spec, @pos_params ) >> is equivalent to
C<< signature( %spec, positional => \@pos_params ) >>.

=head2 C<< compile_named( @named_params ) >>

Equivalent to C<< signature( bless => 0, named => \@named_params ) >>.

C<< compile_named( \%spec, @named_params ) >> is equivalent to
C<< signature( bless => false, %spec, named => \@named_params ) >>.

=head2 C<< compile_named_oo( @named_params ) >>

Equivalent to C<< signature( bless => true, named => \@named_params ) >>.

C<< compile_named_oo( \%spec, @named_params ) >> is equivalent to
C<< signature( bless => true, %spec, named => \@named_params ) >>.

=head2 C<< validate( \@args, @pos_params ) >>

Equivalent to C<< signature( positional => \@pos_params )->( @args ) >>.

The C<validate> function has I<never> been recommended, and is not
exported unless requested by name.

=head2 C<< validate_named( \@args, @named_params ) >>

Equivalent to C<< signature( bless => false, named => \@named_params )->( @args ) >>.

The C<validate_named> function has I<never> been recommended, and is not
exported unless requested by name.

=head2 C<< wrap_subs( func1 => \@params1, func2 => \@params2, ... ) >>

Equivalent to:

 signature_for func1 => ( positional => \@params1 );
 signature_for func2 => ( positional => \@params2 );

One slight difference is that instead of arrayrefs, you can provide the
output of one of the C<compile> functions:

 wrap_subs( func1 => compile_named( @params1 ) );

C<wrap_subs> is not exported unless requested by name.

=head2 C<< wrap_methods( func1 => \@params1, func2 => \@params2, ... ) >>

Equivalent to:

 signature_for func1 => ( method => 1, positional => \@params1 );
 signature_for func2 => ( method => 1, positional => \@params2 );

One slight difference is that instead of arrayrefs, you can provide the
output of one of the C<compile> functions:

 wrap_methods( func1 => compile_named( @params1 ) );

C<wrap_methods> is not exported unless requested by name.

=head2 C<< multisig( @alternatives ) >>

Equivalent to:

 signature( multiple => \@alternatives )

C<< multisig( \%spec, @alternatives ) >> is equivalent to
C<< signature( %spec, multiple => \@alternatives ) >>.

=head1 TYPE CONSTRAINTS

Although Type::Params is not a real type library, it exports two type
constraints. Their use is no longer recommended.

=head2 B<Invocant>

Type::Params exports a type B<Invocant> on request. This gives you a type
constraint which accepts classnames I<and> blessed objects.

 use Type::Params qw( compile Invocant );
 
 signature_for my_method => (
   method     => Invocant,
   positional => [ ArrayRef, Int ],
 );
 
 sub my_method ($self_or_class, $arr, $ix) {
   return $arr->[ $ix ];
 }

C<Invocant> is not exported unless requested by name.

Recommendation: use B<Defined> from L<Types::Standard> instead.

=head2 B<ArgsObject>

Type::Params exports a parameterizable type constraint B<ArgsObject>.
It accepts the kinds of objects returned by signature checks for named
parameters.

  use v5.36;
  
  package Foo {
    use Moo;
    use Type::Params 'ArgsObject';
    
    has args => (
      is  => 'ro',
      isa => ArgsObject['Bar::bar'],
    );
  }
  
  package Bar {
    use Types::Standard -types;
    use Type::Params 'signature_for';
    
    signature_for bar => ( named => [ xxx => Int, yyy => ArrayRef ] );
    
    sub bar ( $got ) {
      return 'Foo'->new( args => $got );
    }
  }
  
  Bar::bar( xxx => 42, yyy => [] );

The parameter "Bar::bar" refers to the caller when the check is compiled,
rather than when the parameters are checked.

C<ArgsObject> is not exported unless requested by name.

Recommendation: use B<Object> from L<Types::Standard> instead.

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

L<The Type::Tiny homepage|https://typetiny.toby.ink/>.

L<Type::Tiny>, L<Type::Coercion>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
