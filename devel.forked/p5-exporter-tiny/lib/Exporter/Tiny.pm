package Exporter::Tiny;

use 5.006001;
use strict;
use warnings; no warnings qw(void once uninitialized numeric redefine);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.028';
our @EXPORT_OK = qw< mkopt mkopt_hash _croak >;

sub _croak ($;@) { require Carp; my $fmt = shift; @_ = sprintf($fmt, @_); goto \&Carp::croak }

sub import
{
	my $class       = shift;
	my $global_opts = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
	my @args        = do { no strict qw(refs); @_ ? @_ : @{"$class\::EXPORT"} };
	my $opts        = mkopt(\@args);
	
	$global_opts->{into} = caller unless exists $global_opts->{into};
	my @want;
	
	while (@$opts)
	{
		my $opt = shift @{$opts};
		my ($name, $value) = @$opt;
		
		$name =~ /^[:-](.+)$/
			? push(@$opts, $class->_exporter_expand_tag($1, $value, $global_opts))
			: push(@want, $opt);
	}
	
	$class->_exporter_validate_opts($global_opts);
	my $permitted = $class->_exporter_permitted_regexp($global_opts);
	
	for my $wanted (@want)
	{
		my %symbols = $class->_exporter_expand_sub(@$wanted, $global_opts, $permitted);
		$class->_exporter_install_sub($_, $wanted->[1], $global_opts, $symbols{$_})
			for keys %symbols;
	}
}

# Called once per import, passed the "global" import options. Expected to
# validate the import options and carp or croak if there are problems. Can
# also take the opportunity to do other stuff if needed.
#
sub _exporter_validate_opts
{
	1;
}

# Given a tag name, looks it up in %EXPORT_TAGS and returns the list of
# associated functions. The default implementation magically handles tags
# "all" and "default". The default implementation interprets any undefined
# tags as being global options.
# 
sub _exporter_expand_tag
{
	no strict qw(refs);
	
	my $class = shift;
	my ($name, $value, $globals) = @_;
	my $tags  = \%{"$class\::EXPORT_TAGS"};
	
	return map [$_ => $value], $tags->{$name}->($class, @_)
		if ref($tags->{$name}) eq q(CODE);
	
	return map [$_ => $value], @{$tags->{$name}}
		if exists $tags->{$name};
	
	return map [$_ => $value], @{"$class\::EXPORT"}, @{"$class\::EXPORT_OK"}
		if $name eq 'all';
	
	return map [$_ => $value], @{"$class\::EXPORT"}
		if $name eq 'default';
	
	$globals->{$name} = $value || 1;
	return;
}

# Helper for _exporter_expand_sub. Returns a regexp matching all subs in
# the exporter package which are available for export.
#
sub _exporter_permitted_regexp
{
	no strict qw(refs);
	my $class = shift;
	my $re = join "|", map quotemeta, sort {
		length($b) <=> length($a) or $a cmp $b
	} @{"$class\::EXPORT"}, @{"$class\::EXPORT_OK"};
	qr{^(?:$re)$}ms;
}

# Given a sub name, returns a hash of subs to install (usually just one sub).
# Keys are sub names, values are coderefs.
#
sub _exporter_expand_sub
{
	my $class = shift;
	my ($name, $value, $globals, $permitted) = @_;
	$permitted ||= $class->_exporter_permitted_regexp($globals);
	
	no strict qw(refs);
	
	if ($name =~ $permitted)
	{
		my $generator = $class->can("_generate_$name");
		return $name => $class->$generator($name, $value, $globals) if $generator;
		
		my $sub = $class->can($name);
		return $name => $sub if $sub;
	}
	
	$class->_exporter_fail(@_);
}

# Called by _exporter_expand_sub if it is unable to generate a key-value
# pair for a sub.
#
sub _exporter_fail
{
	my $class = shift;
	my ($name, $value, $globals) = @_;
	_croak("Could not find sub '$name' to export in package '$class'");
}

# Actually performs the installation of the sub into the target package. This
# also handles renaming the sub.
#
sub _exporter_install_sub
{
	my $class = shift;
	my ($name, $value, $globals, $sym) = @_;
	
	my $into      = $globals->{into};
	my $installer = $globals->{installer} || $globals->{exporter};
	
	$name = $value->{-as} || $name;
	unless (ref($name) eq q(SCALAR))
	{
		my ($prefix) = grep defined, $value->{-prefix}, $globals->{prefix}, q();
		my ($suffix) = grep defined, $value->{-suffix}, $globals->{suffix}, q();
		$name = "$prefix$name$suffix";
	}
	
	return $installer->($globals, [$name, $sym]) if $installer;
	return ($$name = $sym)                       if ref($name) eq q(SCALAR);
	return ($into->{$name} = $sym)               if ref($into) eq q(HASH);
	
	require B;
	for (grep ref, $into->can($name))
	{
		my $stash = B::svref_2object($_)->STASH;
		next unless $stash->can("NAME");
		$stash->NAME eq $into
			and _croak("Refusing to overwrite local sub '$name' with export from $class");
	}
	
	no strict qw(refs);
	*{"$into\::$name"} = $sym;
}

sub mkopt
{
	my $in = shift or return [];
	my @out;
	
	$in = [map(($_ => ref($in->{$_}) ? $in->{$_} : ()), sort keys %$in)]
		if ref($in) eq q(HASH);
	
	for (my $i = 0; $i < @$in; $i++)
	{
		my $k = $in->[$i];
		my $v;
		
		($i == $#$in)         ? ($v = undef) :
		!defined($in->[$i+1]) ? (++$i, ($v = undef)) :
		!ref($in->[$i+1])     ? ($v = undef) :
		($v = $in->[++$i]);
		
		push @out, [ $k => $v ];
	}
	
	\@out;
}

sub mkopt_hash
{
	my $in  = shift or return;
	my %out = map +($_->[0] => $_->[1]), @{ mkopt($in) };
	\%out;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Exporter::Tiny - an exporter with the features of Sub::Exporter but only core dependencies

=head1 SYNOPSIS

   package MyUtils;
   use base "Exporter::Tiny";
   our @EXPORT = qw(frobnicate);
   sub frobnicate { my $n = shift; ... }
   1;

   package MyScript;
   use MyUtils "frobnicate" => { -as => "frob" };
   print frob(42);
   exit;

=head1 DESCRIPTION

Exporter::Tiny supports many of Sub::Exporter's external-facing features
including renaming imported functions with the C<< -as >>, C<< -prefix >> and
C<< -suffix >> options; explicit destinations with the C<< into >> option;
and alternative installers with the C<< installler >> option. But it's written
in only about 40% as many lines of code and with zero non-core dependencies.

Its internal-facing interface is closer to Exporter.pm, with configuration
done through the C<< @EXPORT >>, C<< @EXPORT_OK >> and C<< %EXPORT_TAGS >>
package variables.

Exporter::Tiny performs most of its internal duties (including resolution
of tag names to sub names, resolution of sub names to coderefs, and
installation of coderefs into the target package) as method calls, which
means they can be overridden to provide interesting behaviour.

=head2 Utility Functions

These are really for internal use, but can be exported if you need them.

=over

=item C<< mkopt(\@array) >>

Similar to C<mkopt> from L<Data::OptList>. It doesn't support all the
fancy options that Data::OptList does (C<moniker>, C<require_unique>,
C<must_be> and C<name_test>) but runs about 50% faster.

=item C<< mkopt_hash(\@array) >>

Similar to C<mkopt_hash> from L<Data::OptList>. See also C<mkopt>.

=back

=head1 TIPS AND TRICKS IMPORTING FROM EXPORTER::TINY

For the purposes of this discussion we'll assume we have a module called
C<< MyUtils >> which exports one function, C<< frobnicate >>. C<< MyUtils >>
inherits from Exporter::Tiny.

Many of these tricks may seem familiar from L<Sub::Exporter>. That is
intentional. Exporter::Tiny doesn't attempt to provide every feature of
Sub::Exporter, but where it does it usually uses a fairly similar API.

=head2 Basic importing

   # import "frobnicate" function
   use MyUtils "frobnicate";

   # import all functions that MyUtils offers
   use MyUtils -all;

=head2 Renaming imported functions

   # call it "frob"
   use MyUtils "frobnicate" => { -as => "frob" };

   # call it "my_frobnicate"
   use MyUtils "frobnicate" => { -prefix => "my_" };

   # call it "frobnicate_util"
   use MyUtils "frobnicate" => { -suffix => "_util" };

   # import it twice with two different names
   use MyUtils
      "frobnicate" => { -as => "frob" },
      "frobnicate" => { -as => "frbnct" };

=head2 Lexical subs

   {
      use Sub::Exporter::Lexical lexical_installer => { -as => "lex" };
      use MyUtils { installer => lex }, "frobnicate";
      
      frobnicate(...);  # ok
   }
   
   frobnicate(...);  # not ok

=head2 Import functions into another package

   use MyUtils { into => "OtherPkg" }, "frobnicate";
   
   OtherPkg::frobincate(...);

=head2 Import functions into a scalar

   my $func;
   use MyUtils "frobnicate" => { -as => \$func };
   
   $func->(...);

=head2 Import functions into a hash

OK, Sub::Exporter doesn't do this...

   my %funcs;
   use MyUtils { into => \%funcs }, "frobnicate";
   
   $funcs{frobnicate}->(...);

=head1 TIPS AND TRICKS EXPORTING USING EXPORTER::TINY

Simple configuration works the same as L<Exporter>; inherit from this module,
and use the C<< @EXPORT >>, C<< @EXPORT_OK >> and C<< %EXPORT_TAGS >>
package variables to list subs to export.

=head2 Generators

Exporter::Tiny has always allowed exported subs to be generated (like
L<Sub::Exporter>), but until version 0.025 did not have an especially nice
API for it.

Now, it's easy. If you want to generate a sub C<foo> to export, list it in
C<< @EXPORT >> or C<< @EXPORT_OK >> as usual, and then simply give your
exporter module a class method called C<< _generate_foo >>.

   push @EXPORT_OK, 'foo';
   
   sub _generate_foo {
      my $class = shift;
      my ($name, $args, $globals) = @_;
      
      return sub {
         ...;
      }
   }

You can also generate tags:

   my %constants = (FOO => 1, BAR => 2);
   use constant \%constants;
   
   $EXPORT_TAGS{constants} = sub {
      my $class = shift;
      my ($name, $args, $globals) = @_;
      
      return keys(%constants);
   };

=head2 Overriding Internals

An important difference between L<Exporter> and Exporter::Tiny is that
the latter calls all its internal functions as I<< class methods >>. This
means that your subclass can I<< override them >> to alter their behaviour.

The following methods are available to be overridden. Despite being named
with a leading underscore, they are considered public methods. (The underscore
is there to avoid accidentally colliding with any of your own function names.)

=over

=item C<< _exporter_validate_opts($globals) >>

This method is called once each time C<import> is called. It is passed a
reference to the global options hash. (That is, the optional leading hashref
in the C<use> statement, where the C<into> and C<installer> options can be
provided.)

You may use this method to munge the global options, or validate them,
throwing an exception or printing a warning.

The default implementation does nothing interesting.

=item C<< _exporter_expand_tag($name, $args, $globals) >>

This method is called to expand an import tag (e.g. C<< ":constants" >>).
It is passed the tag name (minus the leading ":"), an optional hashref
of options (like C<< { -prefix => "foo_" } >>), and the global options
hashref.

It is expected to return a list of ($name, $args) arrayref pairs. These
names can be sub names to export, or further tag names (which must have
their ":"). If returning tag names, be careful to avoid creating a tag
expansion loop!

The default implementation uses C<< %EXPORT_TAGS >> to expand tags, and
provides fallbacks for the C<< :default >> and C<< :all >> tags.

=item C<< _exporter_expand_sub($name, $args, $globals) >>

This method is called to translate a sub name to a hash of name => coderef
pairs for exporting to the caller. In general, this would just be a hash with
one key and one value, but, for example, L<Type::Library> overrides this
method so that C<< "+Foo" >> gets expanded to:

   (
      Foo         => sub { $type },
      is_Foo      => sub { $type->check(@_) },
      to_Foo      => sub { $type->assert_coerce(@_) },
      assert_Foo  => sub { $type->assert_return(@_) },
   )

The default implementation checks that the name is allowed to be exported
(using the C<_exporter_permitted_regexp> method), gets the coderef using
the generator if there is one (or by calling C<< can >> on your exporter
otherwise) and calls C<_exporter_fail> if it's unable to generate or
retrieve a coderef.

=item C<< _exporter_permitted_regexp($globals) >>

This method is called to retrieve a regexp for validating the names of
exportable subs. If a sub doesn't match the regexp, then the default
implementation of C<_exporter_expand_sub> will refuse to export it. (Of
course, you may override the default C<_exporter_expand_sub>.)

The default implementation of this method assembles the regexp from
C<< @EXPORT >> and C<< @EXPORT_OK >>.

=item C<< _exporter_fail($name, $args, $globals) >>

Called by C<_exporter_expand_sub> if it can't find a coderef to export.

The default implementation just throws an exception. But you could emit
a warning instead, or just ignore the failed export.

If you don't throw an exception then you should be aware that this
method is called in list context, and any list it returns will be treated
as an C<_exporter_expand_sub>-style hash of names and coderefs for
export.

=item C<< _exporter_install_sub($name, $args, $globals, $coderef) >>

This method actually installs the exported sub into its new destination.
Its return value is ignored.

The default implementation handles sub renaming (i.e. the C<< -as >>,
C<< -prefix >> and C<< -suffix >> functions. This method does a lot of
stuff; if you need to override it, it's probably a good idea to just
pre-process the arguments and then call the super method rather than
trying to handle all of it yourself.

=back

=head1 HISTORY

L<Type::Library> had a bunch of custom exporting code which poked coderefs
into its caller's stash. It needed this to be something more powerful than
most exporters so that it could switch between exporting Moose, Mouse and
Moo-compatible objects on request. L<Sub::Exporter> would have been capable,
but had too many dependencies for the Type::Tiny project.

Meanwhile L<Type::Utils>, L<Types::TypeTiny> and L<Test::TypeTiny> each
used the venerable L<Exporter.pm|Exporter>. However, this meant they were
unable to use the features like L<Sub::Exporter>-style function renaming
which I'd built into Type::Library:

   ## import "Str" but rename it to "String".
   use Types::Standard "Str" => { -as => "String" };

And so I decided to factor out code that could be shared by all Type-Tiny's
exporters into a single place: L<Exporter::TypeTiny>.

As of version 0.026, L<Exporter::TypeTiny> was also made available as
L<Exporter::Tiny>, distributed independently on CPAN. CHOCOLATEBOY had
convinced me that it was mature enough to live a life of its own.

As of version 0.030, Type-Tiny depends on Exporter::Tiny and
L<Exporter::TypeTiny> is being phased out.

=head1 OBLIGATORY EXPORTER COMPARISON

Exporting is unlikely to be your application's performance bottleneck, but
nonetheless here are some comparisons.

B<< Comparative sizes according to L<Devel::SizeMe>: >>

   Exporter                     217.1Kb
   Sub::Exporter::Progressive   263.2Kb
   Exporter::Tiny               267.7Kb
   Exporter + Exporter::Heavy   281.5Kb
   Exporter::Renaming           406.2Kb
   Sub::Exporter                701.0Kb

B<< Performance exporting a single sub: >>

              Rate     SubExp    ExpTiny SubExpProg      ExpPM
SubExp      2489/s         --       -56%       -85%       -88%
ExpTiny     5635/s       126%         --       -67%       -72%
SubExpProg 16905/s       579%       200%         --       -16%
ExpPM      20097/s       707%       257%        19%         --

(Exporter::Renaming globally changes the behaviour of Exporter.pm, so could
not be included in the same benchmarks.)

B<< (Non-Core) Dependencies: >>

   Exporter                    -1
   Exporter::Renaming           0
   Exporter::Tiny               0
   Sub::Exporter::Progressive   0
   Sub::Exporter                3

B<< Features: >>

                                      ExpPM   ExpTiny SubExp  SubExpProg
 Can export code symbols............. Yes     Yes     Yes     Yes      
 Can export non-code symbols......... Yes                              
 Groups/tags......................... Yes     Yes     Yes     Yes      
 Config avoids package variables.....                 Yes              
 Allows renaming of subs.............         Yes     Yes     Maybe    
 Install code into scalar refs.......         Yes     Yes     Maybe    
 Can be passed an "into" parameter...         Yes     Yes     Maybe    
 Can be passed an "installer" sub....         Yes     Yes     Maybe    
 Supports generators.................         Yes     Yes              
 Sane API for generators.............         Yes     Yes              

(Certain Sub::Exporter::Progressive features are only available if
Sub::Exporter is installed.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Exporter-Tiny>.

=head1 SEE ALSO

L<Exporter::TypeTiny>,
L<Sub::Exporter>,
L<Exporter>.

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

