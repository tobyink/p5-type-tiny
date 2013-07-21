package Eval::TypeTiny;

use strict;

BEGIN { *HAS_LEXICAL_SUBS = ($] >= 5.018) ? sub(){!!1} : sub(){!!0} };

sub _clean_eval
{
	local $@;
	local $SIG{__DIE__};
	my $r = eval $_[0];
	my $e = $@;
	return ($r, $e);
}

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.018';
our @EXPORT    = qw( eval_closure );
our @EXPORT_OK = qw( HAS_LEXICAL_SUBS );

sub import
{
	# do the shuffle!
	no warnings "redefine";
	our @ISA = qw( Exporter::TypeTiny );
	require Exporter::TypeTiny;
	my $next = \&Exporter::TypeTiny::import;
	*import = $next;
	goto $next;
}

use warnings;

my $sandbox = 0;
sub eval_closure
{
	$sandbox++;
	
	my (%args) = @_;
	my $src    = ref $args{source} eq "ARRAY" ? join("\n", @{$args{source}}) : $args{source};
	
	$args{line}   = 1 unless defined $args{line};
	$args{description} =~ s/[^\w .:-\[\]\(\)\{\}\']//g if defined $args{description};
	$src = qq{#line $args{line} "$args{description}"\n$src} if defined $args{description} && !($^P & 0x10);
	$args{environment} ||= {};
	
#	for my $k (sort keys %{$args{environment}})
#	{
#		next if $k =~ /^\$/ && ref($args{environment}{$k}) =~ /^(SCALAR|REF)$/;
#		next if $k =~ /^\@/ && ref($args{environment}{$k}) eq q(ARRAY);
#		next if $k =~ /^\%/ && ref($args{environment}{$k}) eq q(HASH);
#		
#		require Type::Exception;
#		Type::Exception::croak("Expected a variable name and ref; got %s => %s", $k, $args{environment}{$k});
#	}
	
	my @keys      = sort keys %{$args{environment}};
	my $i         = 0;
	my $source    = join "\n" => (
		"package Eval::TypeTiny::Sandbox$sandbox;",
		"sub {",
		map(
			HAS_LEXICAL_SUBS
				? _make_lexical_assignment($_, $i++)
				: sprintf('my %s = %s{$_[%d]};', $_, substr($_, 0, 1), $i++),
			@keys
		),
		$src,
		"}",
	);
	
	my ($compiler, $e) = _clean_eval($source);
	if ($e)
	{
		chomp $e;
		require Type::Exception::Compilation;
		"Type::Exception::Compilation"->throw(
			code        => (ref $args{source} eq "ARRAY" ? join("\n", @{$args{source}}) : $args{source}),
			errstr      => $e,
			environment => $args{environment},
		);
	}
	
	return $compiler->(@{$args{environment}}{@keys});
}

HAS_LEXICAL_SUBS and eval <<'SUPPORT_LEXICAL_SUBS';
my $tmp;
sub _make_lexical_assignment
{
	my ($key, $index) = @_;
	if (HAS_LEXICAL_SUBS and $key =~ /^\&/) {
		$tmp++;
		my $tmpname = '$__LEXICAL_SUB__'.$tmp;
		my $name    = substr($key, 1);
		return
			"no warnings 'experimental::lexical_subs';".
			"use feature 'lexical_subs';".
			"my $tmpname = \$_[$index];".
			"my sub $name { goto $tmpname };";
	}
	sprintf('my %s = %s{$_[%d]};', $key, substr($key, 0, 1), $index);
}
SUPPORT_LEXICAL_SUBS

1;

__END__

=pod

=encoding utf-8

=for stopwords pragmas

=head1 NAME

Eval::TypeTiny - utility to evaluate a string of Perl code in a clean environment

=head1 DESCRIPTION

This is not considered part of Type::Tiny's public API.

=head2 Functions

This module exports one function, which works much like the similarly named
function from L<Eval::Closure>:

=over

=item C<< eval_closure(source => $source, environment => \%env, %opt) >>

=back

=head2 Constants

The following constant may be exported, but is not exported by default.

=over

=item C<< HAS_LEXICAL_SUBS >>

Boolean indicating whether Eval::TypeTiny has support for lexical subs.
(This feature requires Perl 5.18.)

=back

=head1 EVALUATION ENVIRONMENT

The evaluation is performed in the presence of L<strict>, but the absence of
L<warnings>. (This is different to L<Eval::Closure> which enables warnings for
compiled closures.)

The L<feature> pragma is not active in the evaluation environment, so the
following will not work:

   use feature qw(say);
   use Eval::TypeTiny qw(eval_closure);
   
   my $say_all = eval_closure(
      source => 'sub { say for @_ }',
   );
   $say_all->("Hello", "World");

The L<feature> pragma does not "carry over" into the stringy eval. It is
of course possible to import pragmas into the evaluated string as part of the
string itself:

   use Eval::TypeTiny qw(eval_closure);
   
   my $say_all = eval_closure(
      source => 'sub { use feature qw(say); say for @_ }',
   );
   $say_all->("Hello", "World");

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Eval::Closure>, L<Type::Exception::Compilation>.

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

