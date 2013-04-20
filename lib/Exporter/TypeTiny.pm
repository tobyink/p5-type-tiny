package Exporter::TypeTiny;

use 5.008001;
use strict;   no strict qw(refs);
use warnings; no warnings qw(void once uninitialized numeric redefine);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003_05';
our @EXPORT_OK = qw< mkopt mkopt_hash _croak >;

sub _croak ($;@) {
	require Carp;
	@_ = sprintf($_[0], @_[1..$#_]) if @_ > 1;
	goto \&Carp::croak;
}

sub import
{
	my $class       = shift;
	my $global_opts = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
	my @args        = @_ ? @_ : @{"$class\::EXPORT"};
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
	my $class = shift;
	my ($name, $value, $globals) = @_;
	my $tags  = \%{"$class\::EXPORT_TAGS"};
	
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
	
	exists &{"$class\::$name"} && $name =~ $permitted
		? ($name => \&{"$class\::$name"})
		: $class->_exporter_fail(@_);
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
		my ($prefix) = grep defined, $value->{-prefix}, $globals->{prefix}, '';
		my ($suffix) = grep defined, $value->{-suffix}, $globals->{suffix}, '';
		$name = "$prefix$name$suffix";
	}
	
	return $installer->($globals, [$name, $sym]) if $installer;
	return ($$name = $sym)                       if ref($name) eq q(SCALAR);
	return ($into->{$name} = $sym)               if ref($into) eq q(HASH);
	
	require B;
	for (grep ref, $into->can($name))
	{
		my $cv = B::svref_2object($_);
		$cv->STASH->NAME eq $into
			and _croak("Refusing to overwrite local sub '$name' with export from $class");
	}
	
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
	my %out = map @$_, mkopt($in);
	\%out;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Exporter::TypeTiny - a small exporter used internally by Type::Library and friends

=head1 DESCRIPTION

B<< Y O Y O Y O Y O Y ??? >>

B<< Why >> bundle an exporter with Type-Tiny?

Well, it wasn't always that way. L<Type::Library> had a bunch of custom
exporting code which poked coderefs into its caller's stash. It needed this
so that it could switch between exporting Moose, Mouse and Moo-compatible
objects on request.

Meanwhile L<Type::Utils>, L<Types::TypeTiny> and L<Test::TypeTiny> each
used the venerable L<Exporter.pm|Exporter>. However, this meant they were
unable to use the features like L<Sub::Exporter>-style function renaming
which I'd built into Type::Library:

   ## import "Str" but rename it to "String".
   use Types::Standard "Str" => { -as => "String" };

And so I decided to factor out code that could be shared by all Type-Tiny's
exporters into a single place.

Exporter::TypeTiny supports many of Sub::Exporter's external-facing features
including renaming imported functions with the C<< -as >>, C<< -prefix >> and
C<< -suffix >> options; explicit destinations with the C<< into >> option;
and alternative installers with the C<< installler >> option. But it's written
in only about 40% as many lines of code and has with zero non-core dependencies.

Its internal-facing interface is closer to Exporter.pm, with configuration
done through the C<< @EXPORT >>, C<< @EXPORT_OK >> and C<< %EXPORT_TAGS >>
package variables.

Although builders are not an explicit part of the interface,
Exporter::TypeTiny performs most of its internal duties (including resolution
of tag names to function names, resolution of function names to coderefs, and
installation of coderefs into the target package) as method calls, which
means they can be overridden to provide interesting behaviour. These are not
currently documented, and are still subject to change.

=head2 Functions

These are really for internal use, but can be exported if you need them.

=over

=item C<< mkopt(\@array) >>

Similar to C<mkopt> from L<Data::OptList>. It doesn't support all the
fancy options that Data::OptList does (C<moniker>, C<require_unique>,
C<must_be> and C<name_test>) but runs about 50% faster.

=item C<< mkopt_hash(\@array) >>

Similar to C<mkopt_hash> from L<Data::OptList>. See also C<mkopt>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Library>.

L<Exporter>,
L<Sub::Exporter>,
L<Sub::Exporter::Progressive>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITAerTION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

