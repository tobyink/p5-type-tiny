package Types::Standard::Tuple;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::Tuple::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::Tuple::VERSION   = '0.046';
}

use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

my $_Optional = Types::Standard::Optional;

no warnings;

sub __constraint_generator
{
	my @constraints = @_;
	my $slurpy;
	if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
	{
		$slurpy = Types::TypeTiny::to_TypeTiny(pop(@constraints)->{slurpy});
		Types::TypeTiny::TypeTiny->check($slurpy)
			or _croak("Slurpy parameter to Tuple[...] expected to be a type constraint; got $slurpy");
	}
	
	@constraints = map Types::TypeTiny::to_TypeTiny($_), @constraints;
	for (@constraints)
	{
		Types::TypeTiny::TypeTiny->check($_)
			or _croak("Parameters to Tuple[...] expected to be type constraints; got $_");
	}
		
	return sub
	{
		my $value = $_[0];
		if ($#constraints < $#$value)
		{
			defined($slurpy) && $slurpy->check(
				$slurpy->is_a_type_of(Types::Standard::HashRef)
					? +{@$value[$#constraints+1 .. $#$value]}
					: +[@$value[$#constraints+1 .. $#$value]]
			) or return;
		}
		for my $i (0 .. $#constraints)
		{
			$i <= $#$value or $constraints[$i]->is_strictly_a_type_of($_Optional) or return;
			$constraints[$i]->check(exists $value->[$i] ? $value->[$i] : ()) or return;
		}
		return !!1;
	};
}

sub __inline_generator
{
	my @constraints = @_;
	my $slurpy;
	if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
	{
		$slurpy = pop(@constraints)->{slurpy};
	}
	
	return if grep { not $_->can_be_inlined } @constraints;
	return if defined $slurpy && !$slurpy->can_be_inlined;
	
	my $tmpl = defined($slurpy) && $slurpy->is_a_type_of(Types::Standard::HashRef)
		? "do { my \$tmp = +{\@{%s}[%d..\$#{%s}]}; %s }"
		: "do { my \$tmp = +[\@{%s}[%d..\$#{%s}]]; %s }";
	
	my $min = 0 + grep !$_->is_strictly_a_type_of($_Optional), @constraints;
	
	return sub
	{
		my $v = $_[1];
		join " and ",
			"ref($v) eq 'ARRAY'",
			"scalar(\@{$v}) >= $min",
			($slurpy
				? sprintf($tmpl, $v, $#constraints+1, $v, $slurpy->inline_check('$tmp'))
				: sprintf("\@{$v} <= %d", scalar @constraints)
			),
			map { $constraints[$_]->inline_check("$v\->[$_]") } 0 .. $#constraints;
	};
}

sub __deep_explanation
{
	my ($type, $value, $varname) = @_;
	
	my @constraints = @{ $type->parameters };
	my $slurpy;
	if (exists $constraints[-1] and ref $constraints[-1] eq "HASH")
	{
		$slurpy = Types::TypeTiny::to_TypeTiny(pop(@constraints)->{slurpy});
	}
	@constraints = map Types::TypeTiny::to_TypeTiny($_), @constraints;
	
	if ($#constraints < $#$value and not $slurpy)
	{
		return [
			sprintf('"%s" expects at most %d values in the array', $type, $#constraints),
			sprintf('%d values found; too many', $#$value),
		];
	}
	
	for my $i (0 .. $#constraints)
	{
		next if $constraints[$i]->is_strictly_a_type_of( Types::Standard::Optional ) && $i > $#$value;
		next if $constraints[$i]->check($value->[$i]);
		
		return [
			sprintf('"%s" constrains value at index %d of array with "%s"', $type, $i, $constraints[$i]),
			@{ $constraints[$i]->validate_explain($value->[$i], sprintf('%s->[%s]', $varname, $i)) },
		];
	}
	
	if (defined($slurpy))
	{
		my $tmp = $slurpy->is_a_type_of(Types::Standard::HashRef)
			? +{@$value[$#constraints+1 .. $#$value]}
			: +[@$value[$#constraints+1 .. $#$value]];
		$slurpy->check($tmp) or return [
			sprintf(
				'Array elements from index %d are slurped into a %s which is constrained with "%s"',
				$#constraints+1,
				$slurpy->is_a_type_of(Types::Standard::HashRef) ? 'hashref' : 'arrayref',
				$slurpy,
			),
			@{ $slurpy->validate_explain($tmp, '$SLURPY') },
		];
	}
	
	return;
}

my $label_counter = 0;
sub __coercion_generator
{
	my ($parent, $child, @tuple) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $slurpy;
	if (exists $tuple[-1] and ref $tuple[-1] eq "HASH")
	{
		$slurpy = pop(@tuple)->{slurpy};
	}
	
	my $all_inlinable = 1;
	for my $tc (@tuple, ($slurpy ? $slurpy : ()))
	{
		$all_inlinable = 0 if !$tc->can_be_inlined;
		$all_inlinable = 0 if $tc->has_coercion && !$tc->coercion->can_be_inlined;
		last if!$all_inlinable;
	}
	
	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Types::Standard::Stringable {
			my $label = sprintf("TUPLELABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, @tmp, @new) = ($_, 0);';
			push @code,       "$label: {";
			push @code,       sprintf('(($return_orig = 1), last %s) if @$orig > %d;', $label, scalar @tuple) unless $slurpy;
			for my $i (0 .. $#tuple)
			{
				my $ct = $tuple[$i];
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional);
				
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
					elsif (not $ct->is_a_type_of(Types::Standard::Optional))
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
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::Tuple - internals for the Types::Standard Tuple type constraint

=head1 STATUS

This module is considered part of Type-Tiny's internals. It is not
covered by the
L<Type-Tiny stability policy|Type::Tiny::Manual::Policies/"STABILITY">.

=head1 DESCRIPTION

This file contains some of the guts for L<Types::Standard>.
It will be loaded on demand. You may ignore its presence.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

