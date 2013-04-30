package Type::Params;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Params::AUTHORITY = 'cpan:TOBYINK';
	$Type::Params::VERSION   = '0.003_11';
}

use Carp qw(croak);
use Eval::TypeTiny;
use Scalar::Util qw(refaddr);
use Type::Utils;
use Types::Standard -types;
use Types::TypeTiny qw(to_TypeTiny);

use base qw< Exporter::TypeTiny >;
our @EXPORT = qw( compile );
our @EXPORT_OK = qw( validate Invocant );

use constant Invocant => union Invocant => [Object, ClassName];

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
			'%s = (($#_-%d)%%2)==0 ? $croaker->("Odd number of elements in %s") : +{ @_[%d..$#_] };',
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
	$env{'$croaker'} = \sub {
		local $Carp::CarpLevel = 4;
		Carp::croak($_[0]);
	};
	my $arg = -1;
	
	while (@_)
	{
		++$arg;
		my $constraint = shift;
		my $is_optional;
		my $varname;
		
		if (HashRef->check($constraint))
		{
			$constraint = to_TypeTiny($constraint->{slurpy});
			push @code,
				$constraint->is_a_type_of(Dict)     ? _mkslurpy('$_', '%', Dict     => $arg) :
				$constraint->is_a_type_of(Map)      ? _mkslurpy('$_', '%', Map      => $arg) :
				$constraint->is_a_type_of(Tuple)    ? _mkslurpy('$_', '@', Tuple    => $arg) :
				$constraint->is_a_type_of(HashRef)  ? _mkslurpy('$_', '%', HashRef  => $arg) :
				$constraint->is_a_type_of(ArrayRef) ? _mkslurpy('$_', '@', ArrayRef => $arg) :
				croak("Slurpy parameter not of type HashRef or ArrayRef");
			$varname = '$_';
		}
		else
		{
			$is_optional = grep $_->{uniq} == Optional->{uniq}, $constraint->parents;
			
			if ($is_optional)
			{
				push @code, sprintf 'return @R if $#_ < %d;', $arg;
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
				'(%s) or $croaker->("Value \\"%s\\" in \\$_[%d] does not meet type constraint \\"%s\\"");',
				$constraint->inline_check($varname),
				$varname,
				$arg,
				$constraint,
			);
		}
		else
		{
			$env{'@check'}[$arg] = $constraint->compiled_check;
			push @code, sprintf(
				'%s or $croaker->("Value \\"%s\\" in \\$_[%d] does not meet type constraint \\"%s\\"");',
				sprintf(sprintf '$check[%d]->(%s)', $arg, $varname),
				$varname,
				$arg,
				$constraint,
			);
		}
		
		push @code, sprintf 'push @R, %s;', $varname;
	}
	
	push @code, '@R;';
	
	my $comment = sprintf('line 0 "parameter validation for %s"', [caller 1]->[3] || '__ANON__');
	my $source  = "# $comment\nsub { no warnings; ".join("\n", @code)." };";
	
	return eval_closure(
		source      => $source,
		environment => \%env,
	);
}

my %compiled;
sub validate
{
	my $arr = shift;
	
	($compiled{ join ":", map($_->{uniq}||"\@$_->{slurpy}", @_) } ||= compile @_)
		->(@$arr);
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

