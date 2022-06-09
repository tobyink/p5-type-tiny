=pod

=encoding utf-8

=head1 PURPOSE

Test inlined Int type check clobbering C<< $1 >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=125132>.

=head1 AUTHOR

Marc Ballarin <marc.ballarin@1und1.de>.

Some modifications by Toby Inkster <tobyink@cpan.org>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Marc Ballarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Type::Params qw(compile);
use Types::Standard qw(Str Int);

{
	my $check;
	sub check_int_tt_compile {
		$check ||= compile(Int);
		my ($int) = $check->(@_);
		is($int, 123, 'check_int_tt_compile');
	}
}

{
	my $check;
	sub check_str_tt {
		$check ||= compile(Str);
		my ($int) = $check->(@_);
		is($int, 123, 'check_str_tt');
	}
}

{
	sub check_int_manual {
		my ($int) = @_;
		die "no Int!" unless $int =~ /^\d+$/;
		is($int, 123, 'check_int_manual');
	}
}

{
	sub check_int_tt_no_compile {
		my ($int) = @_;
		Int->assert_valid($int);
		is($int, 123, 'check_int_tt_no_compile');
	}
}

my $string = 'a123';

subtest 'using temporary variable' => sub {
	if ($string =~ /a(\d+)/) {
		my $matched = $1;
		check_int_tt_compile($matched);
		check_int_manual($matched);
		check_str_tt($matched);
		check_int_tt_no_compile($matched);
	}
};

subtest 'using direct $1' => sub {
	if ($string =~ /a(\d+)/) {
		check_int_tt_compile($1);
		check_int_manual($1);
		check_str_tt($1);
		check_int_tt_no_compile($1);
	}
};

done_testing;
