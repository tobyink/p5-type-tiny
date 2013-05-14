package Type::Exception::Assertion;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Type::Exception::Assertion::AUTHORITY = 'cpan:TOBYINK';
	$Type::Exception::Assertion::VERSION   = '0.005_02';
}

use base "Type::Exception";

sub type       { $_[0]{type} };
sub value      { $_[0]{value} };
sub varname    { $_[0]{varname} ||= '$_' };

sub has_type   { defined $_[0]{type} }; # sic

sub message
{
	my $e = shift;
	$e->varname eq '$_'
		? $e->SUPER::message
		: sprintf('%s (in %s)', $e->SUPER::message, $e->varname);
}

sub _build_message
{
	my $e = shift;
	$e->has_type
		? sprintf('%s did not pass type constraint "%s"', Type::Tiny::_dd($e->value), $e->type)
		: sprintf('%s did not pass type constraint', Type::Tiny::_dd($e->value))
}

sub explain
{
	my $e = shift;
	return [] unless $e->has_type;
	$e->_explain($e->type);
}

sub _explain
{
	my $e = shift;
	my ($type, $value, $varname) = @_;
	$value   = $e->value                    if @_ < 2;
	$varname = ref($e) ? $e->varname : '$_' if @_ < 3;
	
	return unless ref $type;
	return if $type->check($value);
	
	if ($type->has_parent)
	{
		my $parent = $e->_explain($type->parent, $value, $varname);
		return [
			sprintf('"%s" is a subtype of "%s"', $type, $type->parent),
			@$parent,
		] if $parent;
	}
	
	if ($type->is_parameterized and $type->parent->has_deep_explanation)
	{
		my $deep = $type->parent->deep_explanation->($type, $value, $varname);
		return [
			sprintf('%s did not pass type constraint "%s"%s', Type::Tiny::_dd($value), $type, $e->_displayvar($varname)),
			@$deep,
		] if $deep;
	}
	
	return [
		sprintf('%s did not pass type constraint "%s"%s', Type::Tiny::_dd($value), $type, $e->_displayvar($varname)),
		sprintf('"%s" is defined as: %s', $type, $e->_codefor($type)),
	];
}

sub _displayvar
{
	require Type::Tiny;
	shift;
	my ($varname) = @_;
	return '' if $varname eq q{$_};
	return sprintf(' (in %s)', $varname);
}

my $b;
sub _codefor
{
	shift;
	my $type = $_[0];
	
	return $type->inline_check('$_')
		if $type->can_be_inlined;
	
	$b ||= do {
		require B::Deparse;
		my $tmp = "B::Deparse"->new;
		$tmp->ambient_pragmas(strict => "all", warnings => "all");
		$tmp;
	};
	
	my $code = $b->coderef2text($type->constraint);
	$code =~ s/\s+/ /g;
	return "sub $code";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Exception::Assertion - exception when a value fails a type constraint

=head1 DESCRIPTION

This exception is thrown when a value fails a type constraint assertion.

This package inherits from L<Type::Exception>; see that for most
documentation. Major differences are listed below:

=head2 Attributes

=over

=item C<type>

The type constraint that was checked against. Weakened links are involved,
so this may end up being C<undef>.

=item C<value>

The value that was tested.

=item C<varname>

The name of the variable that was checked, if known. Defaults to C<< '$_' >>.

=back

=head2 Methods

=over

=item C<has_type>

Predicate method.

=item C<message>

Overridden to add C<varname> to the message if defined.

=item C<explain>

Attempts to explain why the value did not pass the type constraint. Returns
an arrayref of strings providing step-by-step reasoning; or returns undef if
no explanation is possible.

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

