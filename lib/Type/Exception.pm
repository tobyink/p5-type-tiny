package Type::Exception;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::VERSION   = '0.006';
}

use overload
	q[""]    => sub { $_[0]->to_string },
	fallback => 1,
;

our %CarpInternal;
$CarpInternal{$_}++ for qw(
	Eval::TypeTiny
	Exporter::TypeTiny
	Test::TypeTiny
	Type::Coercion
	Type::Coercion::Union
	Type::Exception
	Type::Library
	Type::Params
	Type::Registry
	Types::Standard
	Types::Standard::DeepCoercion
	Types::TypeTiny
	Type::Tiny
	Type::Tiny::Class
	Type::Tiny::Duck
	Type::Tiny::Enum
	Type::Tiny::Intersection
	Type::Tiny::Role
	Type::Tiny::Union
	Type::Utils
);

sub new
{
	my $class = shift;
	my %params = (@_==1) ? %{$_[0]} : @_;
	return bless \%params, $class;
}

sub throw
{
	my $class = shift;
	
	my ($level, @caller, %ctxt) = 0;
	while (
		(defined scalar caller($level) and $CarpInternal{scalar caller($level)})
		or ( (caller($level))[0] =~ /^Eval::TypeTiny::/ )
	) { $level++ };
	if ( ((caller($level - 1))[1]||"") =~ /^parameter validation for '(.+?)'$/ )
	{
		my ($pkg, $func) = ($1 =~ m{^(.+)::(\w+)$});
		$level++ if caller($level) eq ($pkg||"");
	}
	@ctxt{qw/ package file line /} = caller($level);
	
	die(
		$class->new(context => \%ctxt, @_)
	);
}

sub message    { $_[0]{message} ||= $_[0]->_build_message };
sub context    { $_[0]{context} };

sub to_string
{
	my $e = shift;
	my $c = $e->context;
	my $m = $e->message;
	
	$m =~ /\n\z/s ? $m :
	$c            ? sprintf("%s at %s line %d.\n", $m, $c->{file}, $c->{line}) :
	sprintf("%s\n", $m);
}

sub _build_message
{
	return 'An exception has occurred';
}

sub croak
{
	my ($fmt, @args) = @_;
	@_ = (
		__PACKAGE__,
		message => sprintf($fmt, @args),
	);
	goto \&throw;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Exception - exceptions for Type::Tiny and friends

=head1 SYNOPSIS

   use Data::Dumper;
   use Try::Tiny;
   use Types::Standard qw(Str);
   
   try {
      Str->assert_valid(undef);
   }
   catch {
      my $exception = shift;
      warn "Encountered Error: $exception";
      warn Dumper($exception->explain)
         if $exception->isa("Type::Exception::Assertion");
   };

=head1 DESCRIPTION

When Type::Tiny and its related modules encounter an error, they throw an
exception object. These exception objects inherit from Type::Exception.

=head2 Constructors

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=item C<< throw(%attributes) >>

Constructs an exception and passes it to C<die>.

Automatically populates C<context>.

=back

=head2 Attributes

=over

=item C<message>

The error message.

=item C<context>

Hashref containing the package, file and line that generated the error.

=back

=head2 Methods

=over

=item C<to_string>

Returns the message, followed by the context if it is set.

=back

=head2 Functions

=over

=item C<< Type::Exception::croak($format, @args) >>

Functional-style shortcut to C<throw> method. Takes an C<sprintf>-style
format string and optional arguments to construct the C<message>.

=back

=head2 Overloading

=over

=item *

Stringification is overloaded to call C<to_string>.

=back

=head2 Package Variables

=over

=item C<< %Type::Tiny::CarpInternal >>

Serves a similar purpose to C<< %Carp::CarpInternal >>.

=back

=head1 CAVEATS

Although Type::Exception objects are thrown for errors produced by
Type::Tiny, that doesn't mean every time you use Type::Tiny you'll get
Type::Exceptions whenever you want.

For example, if you use a Type::Tiny type constraint in a Moose attribute,
Moose will not call the constraint's C<assert_valid> method (which throws
an exception). Instead it will call C<check> and C<get_message> (which do
not), and will C<confess> an error message of its own.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Exception::Assertion>,
L<Type::Exception::WrongNumberOfParameters>.

L<Try::Tiny>, L<Try::Tiny::ByClass>.

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

