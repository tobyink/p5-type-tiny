package Type::Params;

use 5.006001;
use strict;
use warnings;

BEGIN {
	if ($] < 5.008) { require Devel::TypeTiny::Perl56Compat };
}

BEGIN {
	$Type::Params::AUTHORITY = 'cpan:TOBYINK';
	$Type::Params::VERSION   = '0.021_02';
}

use B qw(perlstring);
use Eval::TypeTiny;
use Scalar::Util qw(refaddr);
use Type::Exception;
use Type::Exception::Assertion;
use Type::Exception::WrongNumberOfParameters;
use Type::Tiny::Union;
use Types::Standard -types;
use Types::TypeTiny qw(to_TypeTiny);

use base qw< Exporter::TypeTiny >;
our @EXPORT = qw( compile );
our @EXPORT_OK = qw( validate Invocant );

BEGIN {
	my $Invocant = 'Type::Tiny::Union'->new(
		name             => 'Invocant',
		type_constraints => [Object, ClassName],
	);
	sub Invocant () { $Invocant };
};

#sub _exporter_expand_sub
#{
#	my $class = shift;
#	my ($name, $value, $globals, $permitted) = @_;
#	$permitted ||= $class->_exporter_permitted_regexp($globals);
#	
#	my %opts;
#	if ($name eq 'compile' and keys %opts)
#	{
#		return compile => sub { unshift @_, \%opts; goto \&compile };
#	}
#	elsif ($name eq 'validate' and keys %opts)
#	{
#		my %compiled;
#		return validate => sub {
#			my $arr = shift;
#			($compiled{ join ":", map($_->{uniq}||"\@$_->{slurpy}", @_) } ||= compile({ caller_level => 1, %opts }, @_))
#				->(@$arr);
#		};
#	}
#
#	return $class->SUPER::_exporter_expand_sub(@_);
#}

sub _mkslurpy
{
	my ($name, $type, $tc, $i) = @_;
	$type eq '@'
		? sprintf(
			'%s = [ @_[%d..$#_] ];',
			$name,
			$i,
		)
		: sprintf(
			'%s = (($#_-%d)%%2)==0 ? "Type::Exception::WrongNumberOfParameters"->throw(message => "Odd number of elements in %s") : +{ @_[%d..$#_] };',
			$name,
			$i,
			$tc,
			$i,
			$i,
		);
}

sub compile
{
	my (@code, %env);
	@code = 'my (@R, %tmp, $tmp);';
	push @code, '#placeholder';   # $code[1]
	
	my %options    = (ref($_[0]) eq "HASH" && !$_[0]{slurpy}) ? %{+shift} : ();
	my $arg        = -1;
	my $saw_slurpy = 0;
	my $min_args   = 0;
	my $max_args   = 0;
	my $saw_opt    = 0;
	
	while (@_)
	{
		++$arg;
		my $constraint = shift;
		my $is_optional;
		my $is_slurpy;
		my $varname;
		
		if (Bool->check($constraint))
		{
			$constraint = $constraint ? Any : Optional[Any];
		}
		
		if (HashRef->check($constraint))
		{
			$constraint = to_TypeTiny($constraint->{slurpy});
			push @code,
				$constraint->is_a_type_of(Dict)     ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(Map)      ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(Tuple)    ? _mkslurpy('$_', '@', $constraint => $arg) :
				$constraint->is_a_type_of(HashRef)  ? _mkslurpy('$_', '%', $constraint => $arg) :
				$constraint->is_a_type_of(ArrayRef) ? _mkslurpy('$_', '@', $constraint => $arg) :
				Type::Exception::croak("Slurpy parameter not of type HashRef or ArrayRef");
			$varname = '$_';
			$is_slurpy++;
			$saw_slurpy++;
		}
		else
		{
			Type::Exception::croak("Parameter following slurpy parameter") if $saw_slurpy;
			
			$is_optional = grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
			
			if ($is_optional)
			{
				push @code, sprintf 'return @R if $#_ < %d;', $arg;
				$saw_opt++;
				$max_args++;
			}
			else
			{
				Type::Exception::croak("Non-Optional parameter following Optional parameter") if $saw_opt;
				$min_args++;
				$max_args++;
			}
			
			$varname = sprintf '$_[%d]', $arg;
		}
		
		if ($constraint->has_coercion and $constraint->coercion->can_be_inlined)
		{
			push @code, sprintf(
				'$tmp%s = %s;',
				($is_optional ? '{x}' : ''),
				$constraint->coercion->inline_coercion($varname)
			);
			$varname = '$tmp'.($is_optional ? '{x}' : '');
		}
		elsif ($constraint->has_coercion)
		{
			$env{'@coerce'}[$arg] = $constraint->coercion->compiled_coercion;
			push @code, sprintf(
				'$tmp%s = $coerce[%d]->(%s);',
				($is_optional ? '{x}' : ''),
				$arg,
				$varname,
			);
			$varname = '$tmp'.($is_optional ? '{x}' : '');
		}
		
		if ($constraint->can_be_inlined)
		{
			push @code, sprintf(
				'(%s) or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				$constraint->inline_check($varname),
				$constraint->{uniq},
				perlstring($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_[%d]}', $arg),
			);
		}
		else
		{
			$env{'@check'}[$arg] = $constraint->compiled_check;
			push @code, sprintf(
				'%s or Type::Tiny::_failed_check(%d, %s, %s, varname => %s);',
				sprintf(sprintf '$check[%d]->(%s)', $arg, $varname),
				$constraint->{uniq},
				perlstring($constraint),
				$varname,
				$is_slurpy ? 'q{$SLURPY}' : sprintf('q{$_[%d]}', $arg),
			);
		}
		
		push @code, sprintf 'push @R, %s;', $varname;
	}

	if ($min_args == $max_args and not $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Type::Exception::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d, maximum => %d) if @_ != %d;',
			$min_args,
			$max_args,
			$min_args,
		);
	}
	elsif ($min_args < $max_args and not $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Type::Exception::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d, maximum => %d) if @_ < %d || @_ > %d;',
			$min_args,
			$max_args,
			$min_args,
			$max_args,
		);
	}
	elsif ($min_args and $saw_slurpy)
	{
		$code[1] = sprintf(
			'"Type::Exception::WrongNumberOfParameters"->throw(got => scalar(@_), minimum => %d) if @_ < %d;',
			$min_args,
			$min_args,
		);
	}
	
	push @code, '@R;';
	
	my $source  = "sub { no warnings; ".join("\n", @code)." };";
	
	return $source if $options{want_source};
	
	return eval_closure(
		source      => $source,
		description => sprintf("parameter validation for '%s'", [caller(1+($options{caller_level}||0))]->[3] || '__ANON__'),
		environment => \%env,
	);
}

my %compiled;
sub validate
{
	my $arr = shift;
	my $sub = $compiled{ join ":", map($_->{uniq}||"\@$_->{slurpy}", @_) } ||= compile({ caller_level => 1 }, @_);
	@_ = @$arr;
	goto $sub;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Params - Params::Validate-like parameter validation using Type::Tiny type constraints and coercions

=head1 SYNOPSIS

 use v5.10;
 use strict;
 use warnings;
 
 use Type::Params qw( compile );
 use Types::Standard qw( slurpy Str ArrayRef Num );
   
 sub deposit_monies
 {
    state $check = compile( Str, Str, slurpy ArrayRef[Num] );
    my ($sort_code, $account_number, $monies) = $check->(@_);
    
    my $account = Local::BankAccount->new($sort_code, $account_number);
    $account->deposit($_) for @$monies;
 }
 
 deposit_monies("12-34-56", "11223344", 1.2, 3, 99.99);

=head1 DESCRIPTION

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

 my $deposit_monies_check;
 sub deposit_monies
 {
    $deposit_monies_check ||= compile( Str, Str, slurpy ArrayRef[Num] );
    my ($sort_code, $account_number, $monies) = $check->(@_);
    
    ...;
 }

Not quite as neat, but not awful either.

There's a shortcut reducing it to one step:

 use Type::Params qw( validate );
 
 sub deposit_monies
 {
    my ($sort_code, $account_number, $monies) = 
       validate( \@_, Str, Str, slurpy ArrayRef[Num] );
    
    ...;
 }

Type::Params has a few tricks up its sleeve to make sure performance doesn't
suffer too much with the shortcut, but it's never going to be as fast as the
two stage compile/execute.

=begin trustme

Dude, these functions are documented!

=item compile

=item validate

=item Invocant

=end trustme

=head1 COOKBOOK

=head2 Positional Parameters

   sub nth_root
   {
      state $check = compile( Num, Num );
      my ($x, $n) = $check->(@_);
      
      return $x ** (1 / $n);
   }

=head2 Method Calls

Type::Params exports an additional keyword C<Invocant> on request. This is
a type constraint accepting blessed objects and also class names.

   use Types::Standard qw( ClassName Object Str Int );
   use Type::Params qw( compile Invocant );
   
   # a class method
   sub new_from_json
   {
      state $check = compile( ClassName, Str );
      my ($class, $json) = $check->(@_);
      
      $class->new( from_json($json) );
   }
   
   # an object method
   sub dump
   {
      state $check = compile( Object, Int );
      my ($self, $limit) = $check->(@_);
      
      local $Data::Dumper::Maxdepth = $limit;
      print Data::Dumper::Dumper($self);
   }
   
   # can be called as either and object or class method
   sub run
   {
      state $check = compile( Invocant );
      my ($proto) = $check->(@_);
      
      my $self = ref($proto) ? $proto : $default_instance;
      $self->_run;
   }

=head2 Optional Parameters

   use Types::Standard qw( Object Optional Int );
   
   sub dump
   {
      state $check = compile( Object, Optional[Int] );
      my ($self, $limit) = $check->(@_);
      $limit //= 0;
      
      local $Data::Dumper::Maxdepth = $limit;
      print Data::Dumper::Dumper($self);
   }
   
   $obj->dump(1);      # ok
   $obj->dump();       # ok
   $obj->dump(undef);  # dies

=head2 Slurpy Parameters

   use Types::Standard qw( slurpy ClassName HashRef );
   
   sub new
   {
      state $check = compile( ClassName, slurpy HashRef );
      my ($class, $ref) = $check->(@_);
      bless $ref => $class;
   }
   
   __PACKAGE__->new(foo => 1, bar => 2);

The following types from L<Types::Standard> can be made slurpy:
C<ArrayRef>, C<Tuple>, C<HashRef>, C<Map>, C<Dict>. Hash-like types
will die if an odd number of elements are slurped in.

A check may only have one slurpy parameter, and it must be the last
parameter.

=head2 Named Parameters

Just use a slurpy C<Dict>:

   use Types::Standard qw( slurpy Dict Ref Optional Int );
   
   sub dump
   {
      state $check = compile(
         slurpy Dict[
            var    => Ref,
            limit  => Optional[Int],
         ],
      );
      my ($arg) = $check->(@_);
      
      local $Data::Dumper::Maxdepth = $arg->{limit};
      print Data::Dumper::Dumper($arg->{var});
   }
   
   dump(var => $foo, limit => 1);   # ok
   dump(var => $foo);               # ok
   dump(limit => 1);                # dies

=head2 Mixed Positional and Named Parameters

   use Types::Standard qw( slurpy Dict Ref Optional Int );
   
   sub my_print
   {
      state $check = compile(
         Str,
         slurpy Dict[
            colour => Optional[Str],
            size   => Optional[Int],
         ],
      );
      my ($string, $arg) = $check->(@_);
   }
   
   my_print("Hello World", colour => "blue");

=head2 Coercions

Coercions will automatically be applied for I<all> type constraints that have
a coercion associated.

   use Type::Utils;
   use Types::Standard qw( Int Num );
   
   my $RoundedInt = declare as Int;
   coerce $RoundedInt, from Num, q{ int($_) };
   
   sub set_age
   {
      state $check = compile( Object, $RoundedInt );
      my ($self, $age) = $check->(@_);
      
      $self->{age} = $age;
   }
   
   $obj->set_age(32.5);   # ok; coerced to "32".

Coercions carry over into structured types such as C<ArrayRef> automatically:

   sub delete_articles
   {
      state $check = compile( Object, slurpy ArrayRef[$RoundedInt] );
      my ($db, $articles) = $check->(@_);
      
      $db->select_article($_)->delete for @$articles;
   }
   
   # delete articles 1, 2 and 3
   delete_articles($my_db, 1.1, 2.2, 3.3);

If type C<Foo> has coercions from C<Str> and C<ArrayRef> and you want to
B<prevent> coercion, then use:

   state $check = compile( Foo->no_coercions );

Or if you just want to prevent coercion from C<Str>, use:

   state $check = compile( Foo->minus_coercions(Str) );

Or maybe add an extra coercion:

   state $check = compile(
      Foo->plus_coercions(Int, q{ Foo->new_from_number($_) }),
   );

Note that the coercion is specified as a string of Perl code. This is usually
the fastest way to do it, but a coderef is also accepted. Either way, the
value to be coerced is C<< $_ >>.

=head1 COMPARISON WITH PARAMS::VALIDATE

L<Type::Params> is not really a drop-in replacement for L<Params::Validate>;
the API differs far too much to claim that. Yet it performs a similar task,
so it makes sense to compare them.

=over

=item *

Type::Params will tend to be faster if you've got a sub which is called
repeatedly, but may be a little slower than Params::Validate for subs that
are only called a few times. This is because it does a bunch of work the
first time your sub is called to make subsequent calls a lot faster.

=item *

Type::Params is mostly geared towards positional parameters, while
Params::Validate seems to be primarily aimed at named parameters. (Though
either works for either.) Params::Validate doesn't appear to have a
particularly natural way of validating a mix of positional and named
parameters.

=item *

Type::Utils allows you to coerce parameters. For example, if you expect
a L<Path::Tiny> object, you could coerce it from a string.

=item *

Params::Validate allows you to supply defaults for missing parameters;
Type::Params does not, but you may be able to use coercion from Undef.

=item *

If you are primarily writing object-oriented code, using Moose or similar,
and you are using Type::Tiny type constraints for your attributes, then
using Type::Params allows you to use the same constraints for method calls.

=item *

Type::Params comes bundled with Types::Standard, which provides a much
richer vocabulary of types than the type validation constants that come
with Params::Validate. For example, Types::Standard provides constraints
like C<< ArrayRef[Int] >> (an arrayref of integers), while the closest from
Params::Validate is C<< ARRAYREF >>, which you'd need to supplement with
additional callbacks if you wanted to check that the arrayref contained
integers.

Whatsmore, Type::Params doesn't just work with Types::Standard, but also
any other Type::Tiny type constraints.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>, L<Type::Coercion>, L<Types::Standard>.

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

