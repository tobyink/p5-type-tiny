=pod

=encoding utf-8

=head1 PURPOSE

Print some standard diagnostics before beginning testing.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

sub diag_version
{
	my ($module, $version, $return) = @_;
	
	if ($module =~ /\//) {
		my @modules  = split /\s*\/\s*/, $module;
		my @versions = map diag_version($_, undef, 1), @modules;
		return @versions if $return;
		return diag sprintf('  %-43s %s', join("/", @modules), join("/", @versions));
	}
	
	unless (defined $version) {
		eval "use $module ()";
		$version =  $module->VERSION;
	}
	
	if (!defined $version) {
		return 'undef' if $return;
		return diag sprintf('  %-40s    undef', $module);
	}
	
	my ($major, $rest) = split /\./, $version;
	$major =~ s/^v//;
	return "$major\.$rest" if $return;
	return diag sprintf('  %-40s % 4d.%s', $module, $major, $rest);
}

sub diag_env
{
	require B;
	my $var = shift;
	return diag sprintf('  $%-40s   %s', $var, exists $ENV{$var} ? B::perlstring($ENV{$var}) : "undef");
}

sub banner
{
	diag( ' ' );
	diag( '# ' x 36 );
	diag( ' ' );
	diag( "  PERL:     $]" );
	diag( "  XS:       " . ( exists($ENV{PERL_TYPE_TINY_XS}) && !$ENV{PERL_TYPE_TINY_XS} ? 'PP' : 'maybe XS' ) );
	diag( "  NUMBERS:  " . ( $ENV{PERL_TYPES_STANDARD_STRICTNUM} ? 'strict' : 'loose' ) );
	diag( "  TESTING:  " . ( $ENV{EXTENDED_TESTING} ? 'extended' : 'normal' ) );
	diag( "  COVERAGE: " . ( $ENV{COVERAGE} ? 'coverage report' : 'not checking coverage' ) ) if $ENV{TRAVIS};
	diag( ' ' );
	diag( '# ' x 36 );
}

banner();

while (<DATA>)
{
	chomp;
	
	if (/^#\s*(.*)$/ or /^$/)
	{
		diag($1 || "");
		next;
	}

	if (/^\$(.+)$/)
	{
		diag_env($1);
		next;
	}

	if (/^perl$/)
	{
		diag_version("Perl", $]);
		next;
	}
	
	diag_version($_) if /\S/;
}

require Types::Standard;
diag( ' ' );
diag(
	!Types::Standard::Str()->_has_xsub
		? ">>>> Type::Tiny is not using XS"
		: $INC{'Type/Tiny/XS.pm'}
			? ">>>> Type::Tiny is using Type::Tiny::XS"
			: ">>>> Type::Tiny is using Mouse::XS"
);
diag( ' ' );
diag( '# ' x 36 );
diag( ' ' );

ok 1;
done_testing;

__END__

Exporter::Tiny
Return::Type
Type::Tiny::XS

Scalar::Util/Sub::Util
Ref::Util/Ref::Util::XS
Regexp::Util
Class::XSAccessor
Devel::LexAlias/PadWalker
Devel::StackTrace

Class::Tiny
Moo/MooX::TypeTiny
Moose/MooseX::Types
Mouse/MouseX::Types

$AUTOMATED_TESTING
$NONINTERACTIVE_TESTING
$EXTENDED_TESTING
$AUTHOR_TESTING
$RELEASE_TESTING

$PERL_TYPE_TINY_XS
$PERL_TYPES_STANDARD_STRICTNUM
$PERL_ONLY
