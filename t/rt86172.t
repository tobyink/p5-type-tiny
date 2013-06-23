=pod

=encoding utf-8

=head1 PURPOSE

Complex Type::Tiny + Moo + Moose interaction with coercions.

=head1 DEPENDENCIES

Moo 1.002000; Moose 2.0600; skipped otherwise.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=86172>.

=head1 AUTHOR

Peter Flanigan E<lt>pjfl@cpan.orgE<gt>.

(Minor changes by Toby Inkster E<lt>tobyink@cpan.orgE<gt>.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Peter Flanigan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { "Moo"   => "1.002000" };
use Test::Requires { "Moose" => "2.0600" };
use Test::Fatal;

BEGIN {
	plan skip_all => "there have been some issues with this test during automated testing"
		if $ENV{AUTOMATED_TESTING} && $] < 5.010;
};

BEGIN {
	package IO::Class;
	
	sub new    { shift; bless { path => $_[ 0 ] }, 'IO::Class' }
	sub is_dir { -d $_[ 0 ]->path }
	sub path   { $_[ 0 ]->{path} }
	
	$INC{"IO/Class.pm"} = __FILE__;
};

BEGIN {
	package MyTypes;
	use Type::Library -base, -declare => qw( Path Directory );
	use Type::Utils -all;
	
	BEGIN { extends q(Types::Standard) };
	
	declare Path, as Object,
		where { $_->isa( q(IO::Class) ) }, message { 'Wrong class' };
	
	declare Directory, as Path, where { $_->is_dir }, message { 'Not a directory' };
	
	coerce Directory, from Str, via { IO::Class->new( $_ ) };
	
	coerce Path, from Str, via { IO::Class->new( $_ ) };
	
	$INC{"MyTypes.pm"} = __FILE__;
};

{
	package TC1;
	use Moo;
	use MyTypes qw( Directory );
	has 'path' => is => 'ro', isa => Directory, coerce => Directory->coercion;
}

{
	package TC2;
	use Moose;
	extends 'TC1';
}

my $tc = TC2->new( path => 't' );

is($tc->path->path, 't', 'Moose + Inheritance + Type::Tiny + Coercion');

done_testing;
