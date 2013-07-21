package Type::Exception::Compilation;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::Compilation::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::Compilation::VERSION   = '0.018';
}

use base "Type::Exception";

sub code        { $_[0]{code} };
sub environment { $_[0]{environment} ||= {} };
sub errstr      { $_[0]{errstr} };

sub _build_message
{
	my $self = shift;
	sprintf("Failed to compile source because: %s", $self->errstr);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Exception::Compilation - exception for Eval::TypeTiny

=head1 DESCRIPTION

Thrown when compiling a closure fails. Common causes are problems with
inlined type constraints, and syntax errors when coercions are given as
strings of Perl code.

This package inherits from L<Type::Exception>; see that for most
documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<code>

The Perl source code being compiled.

=item C<environment>

Hashref of variables being closed over.

=item C<errstr>

Error message from Perl compiler.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Exception>.

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

