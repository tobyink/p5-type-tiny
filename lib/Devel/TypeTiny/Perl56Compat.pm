package Devel::TypeTiny::Perl56Compat;

use 5.006;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.012001';

$VERSION =~ tr/_//d;

#### B doesn't provide perlstring() in 5.6. Monkey patch it.

use B ();

unless ( exists &B::perlstring ) {
	my $d;
	*B::perlstring = sub {
		no warnings 'uninitialized';
		require Data::Dumper;
		$d ||= 'Data::Dumper'
			->new( [] )->Indent( 0 )->Purity( 0 )->Pad( '' )->Useqq( 1 )
			->Terse( 1 )->Freezer( '' )->Toaster( '' );
		my $perlstring = $d->Values( [ '' . shift ] )->Dump;
		( $perlstring =~ /^"/ ) ? $perlstring : qq["$perlstring"];
	};
} #/ unless ( exists &B::perlstring)

unless ( exists &B::cstring ) {
	*B::cstring = \&B::perlstring;
}

push @B::EXPORT_OK, qw( perlstring cstring );

#### Done!

5.6;

__END__

=pod

=encoding utf-8

=for stopwords pragmas

=head1 NAME

Devel::TypeTiny::Perl56Compat - shims to allow Type::Tiny to run on Perl 5.6.x

=head1 STATUS

This module is considered part of Type-Tiny's internals. It is not
covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This is not considered part of Type::Tiny's public API.

Currently this module just has one job: it patches L<B> to export a
C<perlstring> function, as this was only added in Perl 5.8.0.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-type-tiny/issues>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
