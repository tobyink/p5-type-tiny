package Types::Standard::AutomaticCoercion;

use strict;
use warnings;

BEGIN {
	$Types::Standard::AutomaticCoercion::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::AutomaticCoercion::VERSION   = '0.000_09';
}

my $lib = "Types::Standard"->meta;

$lib->get_type("ArrayRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined)
	{
		my @code;
		push @code, 'do { my ($orig, $return_orig, @new) = ($_, 0);';
		push @code,    'for (@$orig) {';
		push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
		push @code, sprintf('push @new, (%s);', $param->coercion->inline_coercion('$_'));
		push @code,    '}';
		push @code,    '$return_orig ? $orig : \\@new';
		push @code, '}';
		$C->add_type_coercions($parent => "@code");
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my @new;
				for my $item (@$value)
				{
					return $value unless $coercable_item->check($item);
					push @new, $param->coerce($item);
				}
				return \@new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("HashRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined)
	{
		my @code;
		push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
		push @code,    'for (keys %$orig) {';
		push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$orig->{$_}'));
		push @code, sprintf('$new{$_} = (%s);', $param->coercion->inline_coercion('$orig->{$_}'));
		push @code,    '}';
		push @code,    '$return_orig ? $orig : \\%new';
		push @code, '}';
		$C->add_type_coercions($parent => "@code");
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless $coercable_item->check($value->{$k});
					$new{$k} = $param->coerce($value->{$k});
				}
				return \%new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("ScalarRef")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	
	my $coercable_item = $param->coercion->_source_type_union;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ($param->coercion->can_be_inlined)
	{
		my @code;
		push @code, 'do { my ($orig, $return_orig, $new) = ($_, 0);';
		push @code,    'for ($$orig) {';
		push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
		push @code, sprintf('$new = (%s);', $param->coercion->inline_coercion('$_'));
		push @code,    '}';
		push @code,    '$return_orig ? $orig : \\$new';
		push @code, '}';
		$C->add_type_coercions($parent => "@code");
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my $new;
				for my $item ($$value)
				{
					return $value unless $coercable_item->check($item);
					$new = $param->coerce($item);
				}
				return \$new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("Map")->{coercion_generator} = sub
{
	my ($parent, $child, $kparam, $vparam) = @_;
	return unless $kparam->has_coercion || $vparam->has_coercion;
	
	my $kcoercable_item = $kparam->has_coercion ? $kparam->coercion->_source_type_union : $kparam;
	my $vcoercable_item = $vparam->has_coercion ? $vparam->coercion->_source_type_union : $vparam;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	if ((!$kparam->has_coercion or $kparam->coercion->can_be_inlined)
	and (!$vparam->has_coercion or $vparam->coercion->can_be_inlined))
	{
		my @code;
		push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
		push @code,    'for (keys %$orig) {';
		push @code, sprintf('$return_orig++ && last unless (%s);', $kcoercable_item->inline_check('$_'));
		push @code, sprintf('$return_orig++ && last unless (%s);', $vcoercable_item->inline_check('$orig->{$_}'));
		push @code, sprintf('$new{(%s)} = (%s);',
			$kparam->has_coercion ? $kparam->coercion->inline_coercion('$_') : '$_',
			$vparam->has_coercion ? $vparam->coercion->inline_coercion('$orig->{$_}') : '$orig->{$_}',
		);
		push @code,    '}';
		push @code,    '$return_orig ? $orig : \\%new';
		push @code, '}';
		$C->add_type_coercions($parent => "@code");
	}
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless $kcoercable_item->check($k) && $vcoercable_item->check($value->{$k});
					$new{$kparam->has_coercion ? $kparam->coerce($k) : $k} =
						$vparam->has_coercion ? $vparam->coerce($value->{$k}) : $value->{$k};
				}
				return \%new;
			},
		);
	}
	
	return $C;
};

$lib->get_type("Optional")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	return $param->coercion;
};

$lib->get_type("Dict")->{coercion_generator} = sub
{
	my ($parent, $child, %dict) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $all_inlinable = 1;
	for my $tc (values %dict)
	{
		$all_inlinable = 0 if $tc->has_coercion && !$tc->can_be_inlined;
	}
	
#	if ($all_inlinable)
#	{
#		my @code;
#		push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
#		push @code,    'for (keys %$orig) {';
#		push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$orig->{$_}'));
#		push @code, sprintf('$new{$_} = (%s);', $param->coercion->inline_coercion('$orig->{$_}'));
#		push @code,    '}';
#		push @code,    '$return_orig ? $orig : \\%new';
#		push @code, '}';
#		$C->add_type_coercions($parent => "@code");
#	}
#	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %dict)
				{
					my $ct = $dict{$k};
					my @accept;
					
					if ($ct->check($value->{$k}))
					{
						@accept = $value->{$k};
					}
					elsif ($ct->has_coercion)
					{
						my $x = $ct->coerce($value->{$k});
						@accept = $x if $ct->check($x);
					}
					else
					{
						return $value;
					}
					
					if (@accept)
					{
						$new{$k} = $accept[0];
					}
					elsif (not $ct->is_a_type_of(Types::Standard::Optional()))
					{
						return $value;
					}
				}
				
				return \%new;
			},
		);
	}
	
	return $C;
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::AutomaticCoercions - internals for Types::Standard

=head1 DESCRIPTION

This module contains additional code for L<Types::Standard>, allowing
coercions for C<< HashRef[Foo] >>, C<< ArrayRef[Foo] >>, etc to be
automatically generated if C<< Foo >> has a coercion.

It is loaded automatically on demand, and provides no public API.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Types::Standard>.

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

