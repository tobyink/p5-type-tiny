=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<Tied> from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Types::Standard qw( Tied HashRef );
use Type::Utils qw( class_type );

my $a = do {
	package MyTie::Array;
	require Tie::Array;
	our @ISA = qw(Tie::StdArray);
	tie my(@A), __PACKAGE__;
	\@A;
};

my $h = do {
	package MyTie::Hash;
	require Tie::Hash;
	our @ISA = qw(Tie::StdHash);
	tie my(%H), __PACKAGE__;
	\%H
};

my $S;
my $s = do {
	package MyTie::Scalar;
	require Tie::Scalar;
	our @ISA = qw(Tie::StdScalar);
	tie $S, __PACKAGE__;
	\$S;
};

should_pass($a, Tied);
should_pass($h, Tied);
should_pass($s, Tied);

should_fail($S, Tied);

should_pass($a, Tied["MyTie::Array"]);
should_fail($h, Tied["MyTie::Array"]);
should_fail($s, Tied["MyTie::Array"]);
should_fail($a, Tied["MyTie::Hash"]);
should_pass($h, Tied["MyTie::Hash"]);
should_fail($s, Tied["MyTie::Hash"]);
should_fail($a, Tied["MyTie::Scalar"]);
should_fail($h, Tied["MyTie::Scalar"]);
should_pass($s, Tied["MyTie::Scalar"]);

should_pass($a, Tied[ class_type MyTieArray  => { class => "MyTie::Array" } ]);
should_fail($h, Tied[ class_type MyTieArray  => { class => "MyTie::Array" } ]);
should_fail($s, Tied[ class_type MyTieArray  => { class => "MyTie::Array" } ]);
should_fail($a, Tied[ class_type MyTieHash   => { class => "MyTie::Hash" } ]);
should_pass($h, Tied[ class_type MyTieHash   => { class => "MyTie::Hash" } ]);
should_fail($s, Tied[ class_type MyTieHash   => { class => "MyTie::Hash" } ]);
should_fail($a, Tied[ class_type MyTieScalar => { class => "MyTie::Scalar" } ]);
should_fail($h, Tied[ class_type MyTieScalar => { class => "MyTie::Scalar" } ]);
should_pass($s, Tied[ class_type MyTieScalar => { class => "MyTie::Scalar" } ]);

my $intersection = (Tied) & (HashRef);
should_pass($h, $intersection);
should_fail($a, $intersection);
should_fail($s, $intersection);
should_fail({foo=>2}, $intersection);

my $e = exception { Tied[{}] };
like($e, qr/^Parameter to Tied\[.a\] expected to be a class name/, 'weird exception');

done_testing;
