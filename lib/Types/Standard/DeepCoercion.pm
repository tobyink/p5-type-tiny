package Types::Standard::DeepCoercion;

use strict;
use warnings;

BEGIN {
	$Types::Standard::DeepCoercion::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::DeepCoercion::VERSION   = '0.003_15';
}

require Type::Coercion;

sub Stringable (&)
{
	package #private
	Types::Standard::DeepCoercion::_Stringable;
	use overload q[""] => sub { $_[0]{text} ||= $_[0]{code}->() }, fallback => 1;
	bless +{ code => $_[0] };
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
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, @new) = ($_, 0);';
			push @code,    'for (@$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
			push @code, sprintf('push @new, (%s);', $param->coercion->inline_coercion('$_'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\@new';
			push @code, '}';
			"@code";
		});
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
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, %new) = ($_, 0);';
			push @code,    'for (keys %$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$orig->{$_}'));
			push @code, sprintf('$new{$_} = (%s);', $param->coercion->inline_coercion('$orig->{$_}'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			"@code";
		});
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
		$C->add_type_coercions($parent => Stringable {
			my @code;
			push @code, 'do { my ($orig, $return_orig, $new) = ($_, 0);';
			push @code,    'for ($$orig) {';
			push @code, sprintf('$return_orig++ && last unless (%s);', $coercable_item->inline_check('$_'));
			push @code, sprintf('$new = (%s);', $param->coercion->inline_coercion('$_'));
			push @code,    '}';
			push @code,    '$return_orig ? $orig : \\$new';
			push @code, '}';
			"@code";
		});
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
		$C->add_type_coercions($parent => Stringable {
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
			"@code";
		});
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

# XXX - also Maybe[`a]?
# XXX - does not seem quite right
$lib->get_type("Optional")->{coercion_generator} = sub
{
	my ($parent, $child, $param) = @_;
	return unless $param->has_coercion;
	return $param->coercion;
};

my $label_counter = 0;
our ($keycheck_counter, @KEYCHECK) = -1;
$lib->get_type("Dict")->{coercion_generator} = sub
{
	my ($parent, $child, %dict) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $all_inlinable = 1;
	for my $tc (values %dict)
	{
		$all_inlinable = 0 if $tc->has_coercion && !$tc->can_be_inlined;
	}

	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Stringable {
			require B;
			
			my $keycheck = join "|", map quotemeta, sort { length($b) <=> length($a) or $a cmp $b } keys %dict;
			$keycheck = $KEYCHECK[++$keycheck_counter] = qr{^($keycheck)$}ms; # regexp for legal keys
			
			my $label = sprintf("LABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, %tmp, %new) = ($_, 0);';
			push @code,       "$label: {";
			push @code,       sprintf('($_ =~ $%s::KEYCHECK[%d])||(($return_orig = 1), last %s) for sort keys %%$orig;', __PACKAGE__, $keycheck_counter, $label);
			for my $k (keys %dict)
			{
				my $ct = $dict{$k};
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional());
				my $K = B::perlstring($k);
				
				if ($ct_coerce)
				{
					push @code, sprintf('%%tmp = (); $tmp{x} = %s;', $ct->coercion->inline_coercion("\$orig->{$K}"));
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new{%s}=$tmp{x} }'
							: 'if (%s) { $new{%s}=$tmp{x} } else { $return_orig = 1; last %s }',
						$ct->inline_check('$tmp{x}'),
						$K,
						$label,
					);
				}
				else
				{
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new{%s}=$orig->{%s} }'
							: 'if (%s) { $new{%s}=$orig->{%s} } else { $return_orig = 1; last %s }',
						$ct->inline_check("\$orig->{$K}"),
						$K,
						$K,
						$label,
					);
				}
			}
			push @code,       '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			"@code";
		});
	}
	
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				for my $k (keys %$value)
				{
					return $value unless exists $dict{$k};
				}
				for my $k (keys %dict)
				{
					my $ct = $dict{$k};
					my @accept;
					
					if (exists $value->{$k} and $ct->check($value->{$k}))
					{
						@accept = $value->{$k};
					}
					elsif (exists $value->{$k} and $ct->has_coercion)
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

$lib->get_type("Tuple")->{coercion_generator} = sub
{
	my ($parent, $child, @tuple) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);

	my $slurpy;
	if (exists $tuple[-1] and ref $tuple[-1] eq "HASH")
	{
		$slurpy = pop(@tuple)->{slurpy};
	}

	my $all_inlinable = $slurpy ? ($slurpy->has_coercion && $slurpy->can_be_inlined) : 1;
	for my $tc (@tuple)
	{
		$all_inlinable = 0 if $tc->has_coercion && !$tc->can_be_inlined;
	}

	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Stringable {
			my $label = sprintf("LABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, @tmp, @new) = ($_, 0);';
			push @code,       "$label: {";
			push @code,       sprintf('(($return_orig = 1), last %s) if @$orig > %d;', $label, scalar @tuple) unless $slurpy;
			for my $i (0 .. $#tuple)
			{
				my $ct = $tuple[$i];
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional());
				
				if ($ct_coerce)
				{
					push @code, sprintf('@tmp = (); $tmp[0] = %s;', $ct->coercion->inline_coercion("\$orig->[$i]"));
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new[%d]=$tmp[0] }'
							: 'if (%s) { $new[%d]=$tmp[0] } else { $return_orig = 1; last %s }',
						$ct->inline_check('$tmp[0]'),
						$i,
						$label,
					);
				}
				else
				{
					push @code, sprintf(
						$ct_optional
							? 'if (%s) { $new[%d]=$orig->[%s] }'
							: 'if (%s) { $new[%d]=$orig->[%s] } else { $return_orig = 1; last %s }',
						$ct->inline_check("\$orig->[$i]"),
						$i,
						$i,
						$label,
					);
				}
			}
			if ($slurpy)
			{
				my $size = @tuple;
				push @code, sprintf('if (@$orig > %d) {', $size);
				push @code, sprintf('my $tail = [ @{$orig}[%d .. $#$orig] ];', $size);
				push @code, $slurpy->has_coercion
					? sprintf('$tail = %s;', $slurpy->coercion->inline_coercion('$tail'))
					: q();
				push @code, sprintf(
					'(%s) ? push(@new, @$tail) : ($return_orig++);',
					$slurpy->inline_check('$tail'),
				);
				push @code, '}';
			}
			push @code,       '}';
			push @code,    '$return_orig ? $orig : \\@new';
			push @code, '}';
			"@code";
		});
	}
	
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				
				if (!$slurpy and @$value > @tuple)
				{
					return $value;
				}
				
				my @new;
				for my $i (0 .. $#tuple)
				{
					my $ct = $tuple[$i];
					my @accept;
					
					if (exists $value->[$i] and $ct->check($value->[$i]))
					{
						@accept = $value->[$i];
					}
					elsif (exists $value->[$i] and $ct->has_coercion)
					{
						my $x = $ct->coerce($value->[$i]);
						@accept = $x if $ct->check($x);
					}
					else
					{
						return $value;
					}
					
					if (@accept)
					{
						$new[$i] = $accept[0];
					}
					elsif (not $ct->is_a_type_of(Types::Standard::Optional()))
					{
						return $value;
					}
				}
				
				if ($slurpy and @$value > @tuple)
				{
					my $tmp = $slurpy->has_coercion
						? $slurpy->coerce([ @{$value}[@tuple .. $#$value] ])
						: [ @{$value}[@tuple .. $#$value] ];
					$slurpy->check($tmp) ? push(@new, @$tmp) : return($value);
				}
				
				return \@new;
			},
		);
	};
	
	return $C;
};


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::DeepCoercion - internals for Types::Standard

=head1 DESCRIPTION

This module contains additional code for L<Types::Standard>, allowing
coercions for C<< HashRef[Foo] >>, C<< ArrayRef[Foo] >>, etc to be
automatically generated if C<< Foo >> has a coercion.

It provides no public API.

=begin private

=item Stringable

=end private

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

