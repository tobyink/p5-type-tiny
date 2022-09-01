package Type::Params;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ( $] < 5.008 ) { require Devel::TypeTiny::Perl56Compat }
}

BEGIN {
	$Type::Params::AUTHORITY = 'cpan:TOBYINK';
	$Type::Params::VERSION   = '1.016010';
}

$Type::Params::VERSION =~ tr/_//d;

use B qw();
use Eval::TypeTiny;
use Scalar::Util qw(refaddr);
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
	signature signature_for
);

our %EXPORT_TAGS = (
	compile => [ qw( compile compile_named ) ],
	sigs    => [ qw( signature signature_for ) ],
	
	v1      => [ qw( compile compile_named ) ],
	v2      => [ qw( signature signature_for ) ],
);

{
	my $Invocant;
	
	sub Invocant () {
		$Invocant ||= do {
			require Type::Tiny::Union;
			require Types::Standard;
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
			require Types::Standard;
			'Type::Tiny'->new(
				name                 => 'ArgsObject',
				parent               => Types::Standard::Object(),
				constraint           => q{ ref($_) =~ qr/^Type::Params::OO::/ },
				constraint_generator => sub {
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
	
	if ( $] ge '5.014' ) {
		&Scalar::Util::set_prototype( $_, ';$' ) for \&ArgsObject;
	}
}

sub signature {
	require Type::Params::Signature;
	my ( %opts ) = @_;

	my $positional = delete( $opts{positional} ) || delete( $opts{pos} );
	my $named      = delete( $opts{named} );

	my ( $type, $args ) = ( pos => $positional );
	if ( $named ) {
		( $type, $args ) = ( named => $named );
		if ( $positional ) {
			require Error::TypeTiny;
			Error::TypeTiny::croak( "Signature cannot have both positional and named arguments" );
		}
	}

	my $sig = 'Type::Params::Signature'->new_from_compile( $type, \%opts, @$args );
	my $for = [ caller( 1 + ( $opts{caller_level} || 0 ) ) ]->[3] || '__ANON__::__ANON__';
	my ( $pkg, $sub ) = ( $for =~ /^(.+)::(\w+)$/ );
	$sig->{package} ||= $pkg;
	$sig->{subname} ||= $sub;

	$sig->return_wanted;
}

{
	my $subname;
	sub signature_for {
		require Type::Params::Signature;
		my ( $function, %opts ) = @_;
		my $package = caller( $opts{caller_level} || 0 );

		my $positional = delete( $opts{positional} ) || delete( $opts{pos} );
		my $named      = delete( $opts{named} );

		my ( $type, $args ) = ( pos => $positional );
		if ( $named ) {
			( $type, $args ) = ( named => $named );
			if ( $positional ) {
				require Error::TypeTiny;
				Error::TypeTiny::croak( "Signature cannot have both positional and named arguments" );
			}
		}

		my $fullname = "$package\::$function";
		my $orig     = do { no strict 'refs'; \&$fullname };
		$opts{goto_next} = $orig;

		my $sig = 'Type::Params::Signature'->new_from_compile( $type, \%opts, @$args );
		$sig->{package} ||= $package;
		$sig->{subname} ||= $function;
		my $coderef = $sig->return_wanted;

		$subname ||=
			eval { require Sub::Util } ? \&Sub::Util::set_subname :
			eval { require Sub::Name } ? \&Sub::Name::subname :
			sub { pop; };

		no strict 'refs';
		no warnings 'redefine';
		*$fullname = $subname->( $fullname, $coderef );
	}
}

sub compile {
	require Type::Params::Signature;

	my $sig = 'Type::Params::Signature'->new_from_compile( pos => @_ );
	my $for = [ caller( 1 + ( $sig->{caller_level} || 0 ) ) ]->[3] || '__ANON__::__ANON__';
	my ( $pkg, $sub ) = ( $for =~ /^(.+)::(\w+)$/ );
	$sig->{package} ||= $pkg;
	$sig->{subname} ||= $sub;

	$sig->return_wanted;
}

sub compile_named {
	require Type::Params::Signature;

	my $sig = 'Type::Params::Signature'->new_from_compile( named => @_ );
	my $for = [ caller( 1 + ( $sig->{caller_level} || 0 ) ) ]->[3] || '__ANON__::__ANON__';
	my ( $pkg, $sub ) = ( $for =~ /^(.+)::(\w+)$/ );
	$sig->{package} ||= $pkg;
	$sig->{subname} ||= $sub;

	$sig->return_wanted;
}

sub compile_named_oo {
	require Type::Params::Signature;

	my $sig = 'Type::Params::Signature'->new_from_compile( named => { bless => 1 }, @_ );
	my $for = [ caller( 1 + ( $sig->{caller_level} || 0 ) ) ]->[3] || '__ANON__::__ANON__';
	my ( $pkg, $sub ) = ( $for =~ /^(.+)::(\w+)$/ );
	$sig->{package} ||= $pkg;
	$sig->{subname} ||= $sub;

	$sig->return_wanted;
}

# Would be faster to inline this into validate and validate_named, but
# that would complicate them. :/
sub _mk_key {
	local $_;
	join ':', map {
		Types::Standard::is_HashRef( $_ )
			? do {
			my %h = %$_;
			sprintf( '{%s}', _mk_key( map { ; $_ => $h{$_} } sort keys %h ) );
			}
			: Types::TypeTiny::is_TypeTiny( $_ ) ? sprintf( 'TYPE=%s', $_->{uniq} )
			: Types::Standard::is_Ref( $_ )      ? sprintf( 'REF=%s', refaddr( $_ ) )
			: Types::Standard::is_Undef( $_ )    ? sprintf( 'UNDEF' )
			: B::perlstring( $_ )
	} @_;
} #/ sub _mk_key

my %compiled;

sub validate {
	my $arg = shift;
	my $sub = (
		$compiled{ _mk_key( @_ ) } ||= compile(
			{ caller_level => 1, %{ ref( $_[0] ) eq 'HASH' ? shift( @_ ) : +{} } },
			@_,
		)
	);
	@_ = @$arg;
	goto $sub;
} #/ sub validate

my %compiled_named;

sub validate_named {
	my $arg = shift;
	my $sub = (
		$compiled_named{ _mk_key( @_ ) } ||= compile_named(
			{ caller_level => 1, %{ ref( $_[0] ) eq 'HASH' ? shift( @_ ) : +{} } },
			@_,
		)
	);
	@_ = @$arg;
	goto $sub;
} #/ sub validate_named

sub multisig {
	my %options = ( ref( $_[0] ) eq "HASH" ) ? %{ +shift } : ();
	$options{message}     ||= "Parameter validation failed";
	$options{description} ||= sprintf(
		"parameter validation for '%s'",
		[ caller( 1 + ( $options{caller_level} || 0 ) ) ]->[3] || '__ANON__'
	);
	for my $key ( qw[ message description ] ) {
		Types::TypeTiny::is_StringLike( $options{$key} )
			or Error::TypeTiny::croak(
			"Option '$key' expected to be string or stringifiable object" );
	}
	
	my @multi = map {
		Types::TypeTiny::is_CodeLike( $_ )       ? { closure => $_ }
			: Types::TypeTiny::is_ArrayLike( $_ ) ? compile( { want_details => 1 }, @$_ )
			:                                       $_;
	} @_;

	my %env;
	my @code = 'sub { my $r; ';
	
	{
		my ( $extra_env, @extra_lines ) = ( {}, 'my $on_die = undef;' );
		if ( $options{'on_die'} ) {
			my ( $extra_env, @extra_lines ) = ( { '$on_die' => \$options{'on_die'} }, '1;' );
		}
		if ( @extra_lines ) {
			$code[0] .= join '', @extra_lines;
			%env = ( %$extra_env, %env );
		}
	}
	
	for my $i ( 0 .. $#multi ) {
		my $flag = sprintf( '${^TYPE_PARAMS_MULTISIG} = %d', $i );
		my $sig  = $multi[$i];
		my @cond;
		push @cond, sprintf( '@_ >= %s', $sig->{min_args} ) if defined $sig->{min_args};
		push @cond, sprintf( '@_ <= %s', $sig->{max_args} ) if defined $sig->{max_args};
		if ( defined $sig->{max_args} and defined $sig->{min_args} ) {
			@cond = sprintf( '@_ == %s', $sig->{min_args} )
				if $sig->{max_args} == $sig->{min_args};
		}
		push @code, sprintf( 'if (%s){', join( ' and ', @cond ) ) if @cond;
		push @code,
			sprintf(
			'eval { $r = [ $multi[%d]{closure}->(@_) ]; %s };', $i,
			$flag
			);
		push @code, 'return(@$r) if $r;';
		push @code, '}' if @cond;
	} #/ for my $i ( 0 .. $#multi)
	
	push @code,
		sprintf(
		'return "Error::TypeTiny"->throw_cb($on_die, message => "%s");',
		quotemeta( "$options{message}" )
		);
	push @code, '}';
	
	eval_closure(
		source      => \@code,
		description => $options{description},
		environment => { '@multi' => \@multi, %env },
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

{
	my $subname;
	sub _wrap_subs {
		my $opts = shift;
		$subname ||=
			eval   { require Sub::Util } ? \&Sub::Util::set_subname
			: eval { require Sub::Name } ? \&Sub::Name::subname
			: sub { pop; };
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
						'goto_next' => $orig,
						'head'      => $opts->{skip_invocant} ? 1 : 0,
					},
					@$proto,
				);
			}
			no strict 'refs';
			no warnings 'redefine';
			*$fullname = $subname->( $fullname, $new );
		} #/ while ( @_ )
		1;
	} #/ sub _wrap_subs
}

1;

__END__

=pod

=encoding utf-8

=for stopwords evals invocant

=head1 NAME

Type::Params - Params::Validate-like parameter validation using Type::Tiny type constraints and coercions

=head1 SYNOPSIS

 use v5.12;
 use strict;
 use warnings;
 
 package Horse {
   use Moo;
   use Types::Standard qw( Object );
   use Type::Params qw( compile );
   use namespace::autoclean;
   
   ...;   # define attributes, etc
   
   sub add_child {
     state $check = compile( Object, Object );  # method signature
     
     my ($self, $child) = $check->(@_);         # unpack @_
     push @{ $self->children }, $child;
     
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

The first stage is slow (it might take a couple of milliseconds), but you
only need to do it the first time the sub is called. The second stage is
fast; according to my benchmarks faster even than the XS version of
L<Params::Validate>.

If you're using a modern version of Perl, you can use the C<state> keyword
which was a feature added to Perl in 5.10. If you're stuck on Perl 5.8, the
example from the SYNOPSIS could be rewritten as:

   my $add_child_check;
   sub add_child {
     $add_child_check ||= compile( Object, Object );
     
     my ($self, $child) = $add_child_check->(@_);  # unpack @_
     push @{ $self->children }, $child;
     
     return $self;
   }

Not quite as neat, but not awful either.

If you don't like the two step, there's a shortcut reducing it to one step:

   use Type::Params qw( validate );
   
   sub add_child {
     my ($self, $child) = validate(\@_, Object, Object);
     push @{ $self->children }, $child;
     return $self;
   }

Type::Params has a few tricks up its sleeve to make sure performance doesn't
suffer too much with the shortcut, but it's never going to be as fast as the
two stage compile/execute.

=head2 Functions

=head3 C<< compile(@spec) >>

Given specifications for positional parameters, compiles a coderef
that can check against them.

The generalized form of specifications for positional parameters is:

 state $check = compile(
   \%general_opts,
   $type_for_arg_1, \%opts_for_arg_1,
   $type_for_arg_2, \%opts_for_arg_2,
   $type_for_arg_3, \%opts_for_arg_3,
   ...,
   Slurpy[...],
 );

If a hashref of options is empty, it can simply be omitted. Much of the
time, you won't need to specify any options.

 # In this example, we omit all the hashrefs
 #
 my $check = compile(
   Str,
   Int,
   Optional[ArrayRef],
 );
 
 my ($str, $int, $arr) = $check->("Hello", 42, []);   # ok
 my ($str, $int, $arr) = $check->("", -1);            # ok
 my ($str, $int, $arr) = $check->("", -1, "bleh");    # dies

The coderef returned (i.e. C<< $check >>) will check the arguments
passed to it conform to the spec (coercing them if appropriate),
and return them as a list if they do. If they don't, it will throw
an exception.

The first hashref, before any type constraints, is for general options
which affect the entire compiled coderef. Currently supported general
options are:

=over

=item C<< head >> B<< Int|ArrayRef[TypeTiny] >>

Parameters to shift off C<< @_ >> before doing the main type check.
These parameters may also be checked, and cannot be optional or slurpy.
They may not have defaults.

  my $check = compile(
    { head => [ Int, Int ] },
    Str,
    Str,
  );
  
  # ... is basically the same as...
  
  my $check = compile(
    Int,
    Int,
    Str,
    Str,
  );

A number may be given if you do not care to check types:

  my $check = compile(
    { head => 2 },
    Str,
    Str,
  );
  
  # ... is basically the same as...
  
  my $check = compile(
    Any,
    Any,
    Str,
    Str,
  );

This is mostly useless for C<compile>, but can be useful for
C<compile_named> and C<compile_named_oo>.

=item C<< tail >> B<< Int|ArrayRef[TypeTiny] >>

Similar to C<head>, but pops parameters off the end of C<< @_ >> instead.
This is actually useful for C<compile> because it allows you to sneak in
some required parameters I<after> a slurpy or optional parameter.

  my $check = compile(
    { tail => [ CodeRef ] },
    Slurpy[ ArrayRef[Str] ],
  );
  
  my ($strings, $coderef) = $check->("foo", "bar", sub { ... });

=item C<< want_source >> B<< Bool >>

Instead of returning a coderef, return Perl source code string. Handy
for debugging.

=item C<< want_details >> B<< Bool >>

Instead of returning a coderef, return a hashref of stuff including the
coderef. This is mostly for people extending Type::Params and I won't go
into too many details about what else this hashref contains.

=item C<< description >> B<< Str >>

Description of the coderef that will show up in stack traces. Defaults to
"parameter validation for X" where X is the caller sub name.

=item C<< package >> B<< Str >>

The package of the sub we're supposed to be checking. Not usually important.
The default is probably fine.

=item C<< subname >> B<< Str >>

The name of the sub we're supposed to be checking. Not usually important.
The default is probably fine.

If you wish to use the default description, but need to change the sub name,
use this.

=item C<< caller_level >> B<< Int >>

If you wish to use the default description, but need to change the caller
level for detecting the sub name, use this.

=item C<< on_die >> B<< Maybe[CodeRef] >>

  my $check = compile(
    { on_die => sub { ... } },
    ...,
  );
  
  my @args = $check->( @_ );

Normally, at the first invalid argument the C<< $check >> coderef encounters,
it will throw an exception.

If an C<on_die> coderef is provided, then it is called instead, and the
exception is passed to it as an object. The C<< $check >> coderef will still
immediately return though.

=item C<< goto_next >> B<< Bool | CodeLike >>

Defaults to false.

This can be used to turn signatures inside out. Instead of your signature
being a coderef which is called by your function, your function can be a
coderef which is called by the signature.

  # The function people call.
  sub foo {
    state $sig = compile( { goto_next => 1 }, Int );
    $sig->( \&_real_foo, @_ );
  }
  
  # Your real function which receives checked/coerced arguments
  sub _real_foo {
    my ( $n ) = ( @_ );
    ...;
  }

Alternatively, using a coderef:

  sub foo {
    state $sig = compile( { goto_next => \&_real_foo }, Int );
    $sig->( @_ );
  }
  
  sub _real_foo {
    my ( $n ) = ( @_ );
    ...;
  }

Or even:

  {
    my $real_foo = sub {
      my ( $n ) = ( @_ );
      ...;
    };
    *foo = compile( { subname => 'foo', goto_next => $real_foo }, Int );
  }

If you're using Moose/Mouse/Moo, then this should work:

  sub foo {
    my ( $n ) = ( @_ );
    ...;
  }
  
  around foo => compile( { subname => 'foo', goto_next => 1 }, Int );

=item C<< strictness >> B<< Bool | Str >>

If you set C<strictness> to a false value (0, undef, or the empty string), then
certain signature checks will simply never be done. The initial check that
there's the correct number of parameters, plus type checks on parameters which
don't coerce can be skipped.

If you set it to a true boolean (i.e. 1) or do not set it at all, then these
checks will always be done.

Alternatively, it may be set to the quoted fully-qualified name of a Perl
global variable or a constant, and that will be compiled into the coderef
as a condition to enable strict checks.

  state $check = compile(
    { strictness => '$::CHECK_TYPES' },
    Int,
    ArrayRef,
  );
  
  # Type checks are skipped
  {
    local $::CHECK_TYPES = 0;
    my ( $number, $list ) = $check->( {}, {} );
  }
  
  # Type checks are performed
  {
    local $::CHECK_TYPES = 1;
    my ( $number, $list ) = $check->( {}, {} );
  }

A recommended use of this is with L<Devel::StrictMode>.

  use Devel::StrictMode qw( STRICT );
  state $check = compile( { strictness => STRICT }, Int, ArrayRef );

=back

The types for each parameter may be any L<Type::Tiny> type constraint, or
anything that Type::Tiny knows how to coerce into a Type::Tiny type
constraint, such as a MooseX::Types type constraint or a coderef.

Type coercions are automatically applied for all types that have
coercions.

If you wish to avoid coercions for a type, use Type::Tiny's
C<no_coercions> method.

 my $check = compile(
   Int,
   ArrayRef->of(Bool)->no_coercions,
 );

Note that having any coercions in a specification, even if they're not
used in a particular check, will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

Optional parameters can be given using the B<< Optional[] >> type
constraint. In the example above, the third parameter is optional.
If it's present, it's required to be an arrayref, but if it's absent,
it is ignored.

Optional parameters need to be I<after> required parameters in the
spec.

An alternative way to specify optional parameters is using a parameter
options hashref.

 my $check = compile(
   Str,
   Int,
   ArrayRef, { optional => 1 },
 );

The following parameter options are supported:

=over

=item C<< optional >> B<< Bool >>

This is an alternative way of indicating that a parameter is optional.

 state $check = compile(
   Int,
   Int, { optional => 1 },
   Optional[Int],
 );

The two are not I<exactly> equivalent. The exceptions thrown will
differ in the type name they mention. (B<Int> versus B<< Optional[Int] >>.)

=item C<< default >> B<< CodeRef|ScalarRef|Ref|Str|Undef >>

A default may be provided for a parameter.

 state $check = compile(
   Int,
   Int, { default => "666" },
   Int, { default => "999" },
 );

Supported defaults are any strings (including numerical ones), C<undef>,
and empty hashrefs and arrayrefs. Non-empty hashrefs and arrayrefs are
I<< not allowed as defaults >>.

Alternatively, you may provide a coderef to generate a default value:

 state $check = compile(
   Int,
   Int, { default => sub { 6 * 111 } },
   Int, { default => sub { 9 * 111 } },
 );

That coderef may generate any value, including non-empty arrayrefs and
non-empty hashrefs. For undef, simple strings, numbers, and empty
structures, avoiding using a coderef will make your parameter processing
faster.

Instead of a coderef, you can use a reference to a string of Perl source
code:

 state $check = compile(
   Int,
   Int, { default => \ '6 * 111' },
   Int, { default => \ '9 * 111' },
 );

The default I<will> be validated against the type constraint, and
potentially coerced.

Note that having any defaults in a specification, even if they're not
used in a particular check, will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

=item C<< clone >> B<Bool>

If this is set to true, it will deep clone incoming values via C<dclone>
from L<Storable> (a core module since Perl 5.7.3).

In the below example, C<< $arr >> is a reference to a I<clone of>
C<< @numbers >>, so pushing additional numbers to it leaves C<< @numbers >>
unaffected.

 sub foo {
   state $check = compile( ArrayRef, { clone => 1 } );
   my ( $arr ) = &$check;
   
   push @$arr, 4, 5, 6;
 }
 
 my @numbers = ( 1, 2, 3 );
 foo( \@numbers );
 
 print "@numbers\n";  ## 1 2 3

=item C<< strictness >> B<< Bool | Str >>

Overrides the signature-wide C<strictness> setting on a per-parameter basis.

=item C<< slurpy >> B<Bool>

The following two should be equivalent:

 my $check = compile( Int, Slurpy[ArrayRef] );
 my $check = compile( Int, ArrayRef, { slurpy => 1 } );

=back

As a special case, the numbers 0 and 1 may be used as shortcuts for
B<< Optional[Any] >> and B<< Any >>.

 # Positional parameters
 state $check = compile(1, 0, 0);
 my ($foo, $bar, $baz) = $check->(@_);  # $bar and $baz are optional

After any required and optional parameters may be a slurpy parameter.
Any additional arguments passed to C<< $check >> will be slurped into
an arrayref or hashref and checked against the slurpy parameter.
Defaults are not supported for slurpy parameters.

Example with a slurpy ArrayRef:

 sub xyz {
   state $check = compile( Int, Int, Slurpy[ ArrayRef[Int] ] );
   my ($foo, $bar, $baz) = $check->(@_);
 }
 
 xyz(1..5);  # $foo = 1
             # $bar = 2
             # $baz = [ 3, 4, 5 ]

Example with a slurpy HashRef:

 my $check = compile(
   Int,
   Optional[Str],
   Slurpy[ HashRef[Int] ],
 );
 
 my ($x, $y, $z) = $check->(1, "y", foo => 666, bar => 999);
 # $x is 1
 # $y is "y"
 # $z is { foo => 666, bar => 999 }

Any type constraints derived from B<ArrayRef> or B<HashRef> should work,
but a type does need to inherit from one of those because otherwise
Type::Params cannot know what kind of structure to slurp the remaining
arguments into.

B<< Slurpy[Any] >> is also allowed as a special case, and is treated as
B<< Slurpy[ArrayRef] >>.

From Type::Params 1.005000 onwards, slurpy hashrefs can be passed in as a
true hashref (which will be shallow cloned) rather than key-value pairs.

 sub xyz {
   state $check = compile(Int, Slurpy[HashRef]);
   my ($num, $hr) = $check->(@_);
   ...
 }
 
 xyz( 5,   foo => 1, bar => 2   );   # works
 xyz( 5, { foo => 1, bar => 2 } );   # works from 1.005000

This feature is only implemented for slurpy hashrefs, not slurpy arrayrefs.

Note that having a slurpy parameter will slightly slow down C<< $check >>
because it means that C<< $check >> can't just check C<< @_ >> and return
it unaltered if it's valid — it needs to build a new array to return.

=head3 C<< validate(\@_, @spec) >>

This example of C<compile>:

 sub foo {
   state $check = compile(@spec);
   my @args = $check->(@_);
   ...;
 }

Can be written using C<validate> as:

 sub foo {
   my @args = validate(\@_, @spec);
   ...;
 }

Performance using C<compile> will I<always> beat C<validate> though.

=head3 C<< compile_named(@spec) >>

C<compile_named> is a variant of C<compile> for named parameters instead
of positional parameters.

The format of the specification is changed to include names for each
parameter:

 state $check = compile_named(
   \%general_opts,
   foo   => $type_for_foo, \%opts_for_foo,
   bar   => $type_for_bar, \%opts_for_bar,
   baz   => $type_for_baz, \%opts_for_baz,
   ...,
   extra => Slurpy[...],
 );

The C<< $check >> coderef will return a hashref.

 my $check = compile_named(
   foo => Int,
   bar => Str, { default => "hello" },
 );
 
 my $args = $check->(foo => 42);
 # $args->{foo} is 42
 # $args->{bar} is "hello"

The C<< %general_opts >> hash supports the same options as C<compile>
plus a few additional options:

=over

=item C<< class >> B<< ClassName >>

The check coderef will, instead of returning a simple hashref, call
C<< $class->new($hashref) >> and return the result.

=item C<< constructor >> B<< Str >>

Specifies an alternative method name instead of C<new> for the C<class>
option described above.

=item C<< class >> B<< Tuple[ClassName, Str] >>

Shortcut for declaring both the C<class> and C<constructor> options at once.

=item C<< bless >> B<< ClassName >>

Like C<class>, but bypass the constructor and directly bless the hashref.

=item C<< named_to_list >> B<< Bool >>

Instead of returning a hashref, return a hash slice.

 myfunc(bar => "x", foo => "y");
 
 sub myfunc {
    state $check = compile_named(
       { named_to_list => 1 },
       foo => Str, { optional => 1 },
       bar => Str, { optional => 1 },
    );
    my ($foo, $bar) = $check->(@_);
    ...; ## $foo is "y" and $bar is "x"
 }

The order of keys for the hash slice is the same as the order of the names
passed to C<compile_named>. For missing named parameters, C<undef> is
returned in the list.

Basically in the above example, C<myfunc> takes named parameters, but
receieves positional parameters.

=item C<< named_to_list >> B<< ArrayRef[Str] >>

As above, but explicitly specify the keys of the hash slice.

=back

Like C<compile>, the numbers 0 and 1 may be used as shortcuts for
B<< Optional[Any] >> and B<< Any >>.

 state $check = compile_named(foo => 1, bar => 0, baz => 0);
 my $args = $check->(@_);  # $args->{bar} and $args->{baz} are optional

Slurpy parameters are slurped into a nested hashref.

  my $check = compile(
    foo    => Str,
    bar    => Optional[Str],
    extra  => Slurpy[ HashRef[Str] ],
  );
  my $args = $check->(foo => "aaa", quux => "bbb");
  
  print $args->{foo}, "\n";             # aaa
  print $args->{extra}{quux}, "\n";     # bbb

B<< slurpy[Any] >> is treated as B<< slurpy[HashRef] >>.

The C<head> and C<tail> options are supported. This allows for a
mixture of positional and named arguments, as long as the positional
arguments are non-optional and at the head and tail of C<< @_ >>.

  my $check = compile(
    { head => [ Int, Int ], tail => [ CodeRef ] },
    foo => Str,
    bar => Str,
    baz => Str,
  );
  
  my ($int1, $int2, $args, $coderef)
    = $check->( 666, 999, foo=>'x', bar=>'y', baz=>'z', sub {...} );
  
  say $args->{bar};  # 'y'

This can be combined with C<named_to_list>:

  my $check = compile(
    { head => [ Int, Int ], tail => [ CodeRef ], named_to_list => 1 },
    foo => Str,
    bar => Str,
    baz => Str,
  );
  
  my ($int1, $int2, $foo, $bar, $baz, $coderef)
    = $check->( 666, 999, foo=>'x', bar=>'y', baz=>'z', sub {...} );
  
  say $bar;  # 'y'

There is one additional parameter option supported, in addition to
the C<optional>, C<default>, C<clone>, and C<slurpy> options already
supported by positional parameters.

=over

=item C<alias> B<< Str|ArrayRef[Str] >>

A list of alternative names for the parameter, or a single alternative
name.

  {
    my $check;
    sub adder {
      $check ||= compile_named(
        first_number   => Int, { alias => [ 'x' ] },
        second_number  => Int, { alias =>   'y'   },
      );
      my ( $arg ) = &$check;
      return $arg->{first_number} + $arg->{second_number};
    }
  }
  
  say adder( first_number => 40, second_number => 2 );    # 42
  say adder( x            => 40, y             => 2 );    # 42
  say adder( first_number => 40, y             => 2 );    # 42
  say adder( first_number => 40, x => 1, y => 2 );        # dies!

=back

=head3 C<< validate_named(\@_, @spec) >>

Like C<compile> has C<validate>, C<compile_named> has C<validate_named>.
Just like C<validate>, it's the slower way to do things, so stick with
C<compile_named>.

=head3 C<< compile_named_oo(@spec) >>

Here's a quick example function:

   sub add_contact_to_database {
      state $check = compile_named(
         dbh     => Object,
         id      => Int,
         name    => Str,
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->{db}->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->{id}, $arg->{name});
   }

Looks simple, right? Did you spot that it will always die with an error
message I<< Can't call method "prepare" on an undefined value >>?

This is because we defined a parameter called 'dbh' but later tried to
refer to it as C<< $arg{db} >>. Here, Perl gives us a pretty clear
error, but sometimes the failures will be far more subtle. Wouldn't it
be nice if instead we could do this?

   sub add_contact_to_database {
      state $check = compile_named_oo(
         dbh     => Object,
         id      => Int,
         name    => Str,
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->dbh->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->id, $arg->name);
   }

If we tried to call C<< $arg->db >>, it would fail because there was
no such method.

Well, that's exactly what C<compile_named_oo> does.

As well as giving you nice protection against mistyped parameter names,
It also looks kinda pretty, I think. Hash lookups are a little faster
than method calls, of course (though Type::Params creates the methods
using L<Class::XSAccessor> if it's installed, so they're still pretty
fast).

An optional parameter C<foo> will also get a nifty C<< $arg->has_foo >>
predicate method. Yay!

C<compile_named_oo> gives you some extra options for parameters, in
addition to the C<optional>, C<default>, C<clone>, C<slurpy>, and
C<alias> options already supported by C<compile_named>.

   sub add_contact_to_database {
      state $check = compile_named_oo(
         dbh     => Object,
         id      => Int,    { default => '0', getter => 'identifier' },
         name    => Str,    { optional => 1, predicate => 'has_name' },
      );
      my $arg = $check->(@_);
      
      my $sth = $arg->dbh->prepare('INSERT INTO contacts VALUES (?, ?)');
      $sth->execute($arg->identifier, $arg->name) if $arg->has_name;
   }

=over

=item C<< getter >> B<< Str >>

The C<getter> option lets you choose the method name for getting the
argument value.

If the parameter has an alias, this currently I<does not> result in
additional getters being defined.

=item C<< predicate >> B<< Str >>

The C<predicate> option lets you choose the method name for checking
the existence of an argument. By setting an explicit predicate method
name, you can force a predicate method to be generated for non-optional
arguments.

If the parameter has an alias, this currently I<does not> result in
additional predicate methods being defined.

=back

The objects returned by C<compile_named_oo> are blessed into lightweight
classes which have been generated on the fly. Don't expect the names of
the classes to be stable or predictable. It's probably a bad idea to be
checking C<can>, C<isa>, or C<DOES> on any of these objects. If you're
doing that, you've missed the point of them.

They don't have any constructor (C<new> method). The C<< $check >>
coderef effectively I<is> the constructor.

=head3 C<< validate_named_oo(\@_, @spec) >>

This function doesn't even exist. :D

=head3 C<< multisig(@alternatives) >>

Type::Params can export a C<multisig> function that compiles multiple
alternative signatures into one, and uses the first one that works:

   state $check = multisig(
      [ Int, ArrayRef ],
      [ HashRef, Num ],
      [ CodeRef ],
   );
   
   my ($int, $arrayref) = $check->( 1, [] );      # okay
   my ($hashref, $num)  = $check->( {}, 1.1 );    # okay
   my ($code)           = $check->( sub { 1 } );  # okay
   
   $check->( sub { 1 }, 1.1 );  # throws an exception

Coercions, slurpy parameters, etc still work.

The magic global C<< ${^TYPE_PARAMS_MULTISIG} >> is set to the index of
the first signature which succeeded.

The present implementation involves compiling each signature independently,
and trying them each (in their given order!) in an C<eval> block. The only
slightly intelligent part is that it checks if C<< scalar(@_) >> fits into
the signature properly (taking into account optional and slurpy parameters),
and skips evals which couldn't possibly succeed.

It's also possible to list coderefs as alternatives in C<multisig>:

   state $check = multisig(
      [ Int, ArrayRef ],
      sub { ... },
      [ HashRef, Num ],
      [ CodeRef ],
      compile_named( needle => Value, haystack => Ref ),
   );

The coderef is expected to die if that alternative should be abandoned (and
the next alternative tried), or return the list of accepted parameters. Here's
a full example:

   sub get_from {
      state $check = multisig(
         [ Int, ArrayRef ],
         [ Str, HashRef ],
         sub {
            my ($meth, $obj) = @_;
            die unless is_Object($obj);
            die unless $obj->can($meth);
            return ($meth, $obj);
         },
      );
      
      my ($needle, $haystack) = $check->(@_);
      
      for (${^TYPE_PARAMS_MULTISIG}) {
         return $haystack->[$needle] if $_ == 0;
         return $haystack->{$needle} if $_ == 1;
         return $haystack->$needle   if $_ == 2;
      }
   }
   
   get_from(0, \@array);      # returns $array[0]
   get_from('foo', \%hash);   # returns $hash{foo}
   get_from('foo', $obj);     # returns $obj->foo
   
The default error message is just C<"Parameter validation failed">.
You can pass an option hashref as the first argument with an informative
message string:

   sub foo {
      state $OptionsDict = Dict[...];
      state $check = multisig(
         { message => 'USAGE: $object->foo(\%options?, $string)' },
         [ Object, $OptionsDict, StringLike ],
         [ Object, StringLike ],
      );
      my ($self, @args) = $check->(@_);
      my ($opts, $str)  = ${^TYPE_PARAMS_MULTISIG} ? ({}, @args) : @_;
      ...;
   }
   
   $obj->foo(\%opts, "Hello");
   $obj->foo("World");

=head3 C<< wrap_subs( $subname1, $wrapper1, ... ) >>

It's possible to turn the check inside-out and instead of the sub calling
the check, the check can call the original sub.

Normal way:

   use Type::Param qw(compile);
   use Types::Standard qw(Int Str);
   
   sub foobar {
      state $check = compile(Int, Str);
      my ($foo, $bar) = @_;
      ...;
   }

Inside-out way:

   use Type::Param qw(wrap_subs);
   use Types::Standard qw(Int Str);
   
   sub foobar {
      my ($foo, $bar) = @_;
      ...;
   }
   
   wrap_subs foobar => [Int, Str];

C<wrap_subs> takes a hash of subs to wrap. The keys are the sub names and the
values are either arrayrefs of arguments to pass to C<compile> to make a check,
or coderefs that have already been built by C<compile>, C<compile_named>, or
C<compile_named_oo>.

=head3 C<< wrap_methods( $subname1, $wrapper1, ... ) >>

C<wrap_methods> also exists, which shifts off the invocant from C<< @_ >>
before the check, but unshifts it before calling the original sub.

   use Type::Param qw(wrap_methods);
   use Types::Standard qw(Int Str);
   
   sub foobar {
      my ($self, $foo, $bar) = @_;
      ...;
   }
   
   wrap_methods foobar => [Int, Str];

=head3 B<Invocant>

Type::Params exports a type B<Invocant> on request. This gives you a type
constraint which accepts classnames I<and> blessed objects.

 use Type::Params qw( compile Invocant );
 
 sub my_method {
   state $check = compile(Invocant, ArrayRef, Int);
   my ($self_or_class, $arr, $ix) = $check->(@_);
   
   return $arr->[ $ix ];
 }

=head3 B<ArgsObject>

Type::Params exports a parameterizable type constraint B<ArgsObject>.
It accepts the kinds of objects returned by C<compile_named_oo> checks.

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
    use Type::Params 'compile_named_oo';
    
    sub bar {
      state $check = compile_named_oo(
        xxx => Int,
        yyy => ArrayRef,
      );
      my $args = &$check;
      
      return 'Foo'->new( args => $args );
    }
  }
  
  Bar::bar( xxx => 42, yyy => [] );

The parameter "Bar::bar" refers to the caller when the check is compiled,
rather than when the parameters are checked.

=head1 ENVIRONMENT

=over

=item C<PERL_TYPE_PARAMS_XS>

Affects the building of accessors for C<compile_named_oo>. If set to true,
will use L<Class::XSAccessor>. If set to false, will use pure Perl. If this
environment variable does not exist, will use L<Class::XSAccessor> if it
is available.

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

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
