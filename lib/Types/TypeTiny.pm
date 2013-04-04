package Types::TypeTiny;

use base "Exporter";

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_05';

our @EXPORT_OK = qw( CodeLike StringLike TypeTiny );

my %cache;

sub StringLike
{
	require Type::Utils;
	require Types::Standard;
	$cache{StringLike} ||= Type::Utils::union(StringLike => [
		Types::Standard::Overload([q[""]]),
		Types::Standard::Str(),
	]);
}

sub CodeLike
{
	require Type::Utils;
	require Types::Standard;
	$cache{CodeLike} ||= Type::Utils::union(CodeLike => [
		Types::Standard::Overload([q[&{}]]),
		Types::Standard::Ref(["CODE"]),
	]);
}

sub TypeTiny
{
	require Type::Utils;
	$cache{TypeTiny} ||= Type::Utils::class_type(TypeTiny => {class=>"Type::Tiny"});
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::TypeTiny - type constraints used internally by Type::Tiny

=head1 DESCRIPTION

Dogfooding.

This isn't a real Type::Library-based type library; that would involve too
much circularity. But it exports some type constraint "constants":

=head2 Types

=over

=item C<< StringLike >>

=item C<< CodeLike >>

=item C<< TypeTiny >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Tiny>.

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

