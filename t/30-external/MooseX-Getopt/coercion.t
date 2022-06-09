=pod

=encoding utf-8

=head1 PURPOSE

Check coercions work with L<MooseX::Getopt>; both mutable and immutable
classes.

=head1 DEPENDENCIES

Test is skipped if Moose 2.0000, MooseX::Getopt 0.63, and
Types::Path::Tiny are not available.

=head1 AUTHOR

Alexander Hartmaier E<lt>abraxxa@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { 'Moose' => '2.0000' };
use Test::Requires { 'MooseX::Getopt' => '0.63' };
use Test::Requires { 'Types::Path::Tiny' => '0' };
use Test::Fatal;
use Test::TypeTiny qw( matchfor );

my @warnings;

BEGIN {
	package Local::Types;
	use Type::Library -base, -declare => qw( Files );
	use Type::Utils -all;
	use Types::Standard -types;
	use Types::Path::Tiny qw( Path to_Path );
	
	declare Files,
		as ArrayRef[ Path ],
		coercion => 1;
	
	coerce Files,
		from Str, via { [ to_Path($_) ] };
	
	$INC{'Local/Types.pm'} = __FILE__;
};

# note explain( Local::Types::Files->moose_type );

{
	package Local::Class;
	
	use Moose;
	use Local::Types -all;
	with 'MooseX::Getopt';
	
	has files => (is => "rw", isa => Files, coerce => 1);
}

my ($e, $o);

my $suffix = "mutable class";
for my $i (0..1)
{
	$e = exception {
		$o = "Local::Class"->new_with_options(
			files => 'foo.bar',
		);
	};
	is($e, undef, "no exception on coercion in constructor - $suffix");
	
	"Local::Class"->meta->make_immutable;
	$suffix = "im$suffix";
}

done_testing;
