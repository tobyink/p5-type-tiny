package Types::Standard::Dict;

use 5.006001;
use strict;
use warnings;

BEGIN {
	$Types::Standard::Dict::AUTHORITY = 'cpan:TOBYINK';
	$Types::Standard::Dict::VERSION   = '0.046';
}

use Types::Standard ();
use Types::TypeTiny ();

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

my $_hash = Types::Standard::HashRef;
my $_map  = Types::Standard::Map;
my $_any  = Types::Standard::Any;

no warnings;

sub __constraint_generator
{
	my $slurpy = ref($_[-1]) eq q(HASH) ? pop(@_)->{slurpy} : undef;
	my %constraints = @_;
	
	while (my ($k, $v) = each %constraints)
	{
		$constraints{$k} = Types::TypeTiny::to_TypeTiny($v);
		Types::TypeTiny::TypeTiny->check($v)
			or _croak("Parameter to Dict[`a] for key '$k' expected to be a type constraint; got $v");
	}
	
	return sub
	{
		my $value = $_[0];
		if ($slurpy)
		{
			my %tmp = map {
				exists($constraints{$_}) ? () : ($_ => $value->{$_})
			} keys %$value;
			return unless $slurpy->check(\%tmp);
		}
		else
		{
			exists($constraints{$_}) || return for sort keys %$value;
		}
		for (sort keys %constraints) {
			my $c = $constraints{$_};
			return unless exists($value->{$_}) || $c->is_strictly_a_type_of(Types::Standard::Optional);
			return unless $c->check( exists $value->{$_} ? $value->{$_} : () );
		}
		return !!1;
	};
}

sub __inline_generator
{
	# We can only inline a parameterized Dict if all the
	# constraints inside can be inlined.
	
	my $slurpy = ref($_[-1]) eq q(HASH) ? pop(@_)->{slurpy} : undef;
	return if $slurpy && !$slurpy->can_be_inlined;
	
	# Is slurpy a very loose type constraint?
	# i.e. Any, Item, Defined, Ref, or HashRef
	my $slurpy_is_any = $slurpy && $_hash->is_a_type_of( $slurpy );
	
	# Is slurpy a parameterized Map, or expressable as a parameterized Map?
	my $slurpy_is_map = $slurpy
		&& $slurpy->is_parameterized
		&& ((
			$slurpy->parent->strictly_equals($_map)
			&& $slurpy->parameters
		)||(
			$slurpy->parent->strictly_equals($_hash)
			&& [ $_any, $slurpy->parameters->[0] ]
		));
	
	my %constraints = @_;
	for my $c (values %constraints)
	{
		next if $c->can_be_inlined;
		return;
	}
	
	my $regexp = join "|", map quotemeta, sort keys %constraints;
	return sub
	{
		require B;
		my $h = $_[1];
		join " and ",
			"ref($h) eq 'HASH'",
			( $slurpy_is_any ? '1'
			: $slurpy_is_map ? do {
				'(not grep {'
				."my \$v = ($h)->{\$_};"
				.sprintf(
					'not((%s) and (%s))',
					$slurpy_is_map->[0]->inline_check('$_'),
					$slurpy_is_map->[1]->inline_check('$v'),
				) ."} keys \%{$h})"
			}
			: $slurpy ? do {
				'do {'
				. "my \$slurpy_tmp = +{ map /\\A(?:$regexp)\\z/ ? () : (\$_ => ($h)->{\$_}), keys \%{$h} };"
				. $slurpy->inline_check('$slurpy_tmp')
				. '}'
			}
			: "not(grep !/\\A(?:$regexp)\\z/, keys \%{$h})" ),
			( map {
				my $k = B::perlstring($_);
				$constraints{$_}->is_strictly_a_type_of( Types::Standard::Optional )
					? $constraints{$_}->inline_check("$h\->{$k}")
					: ( "exists($h\->{$k})", $constraints{$_}->inline_check("$h\->{$k}") )
			} sort keys %constraints ),
	}
}

sub __deep_explanation
{
	require B;
	my ($type, $value, $varname) = @_;
	my @params = @{ $type->parameters };
	
	my $slurpy = ref($params[-1]) eq q(HASH) ? pop(@params)->{slurpy} : undef;
	my %constraints = @params;
			
	for my $k (sort keys %constraints)
	{
		next if $constraints{$k}->parent == Types::Standard::Optional && !exists $value->{$k};
		next if $constraints{$k}->check($value->{$k});
		
		return [
			sprintf('"%s" requires key %s to appear in hash', $type, B::perlstring($k))
		] unless exists $value->{$k};
		
		return [
			sprintf('"%s" constrains value at key %s of hash with "%s"', $type, B::perlstring($k), $constraints{$k}),
			@{ $constraints{$k}->validate_explain($value->{$k}, sprintf('%s->{%s}', $varname, B::perlstring($k))) },
		];
	}
	
	if ($slurpy)
	{
		my %tmp = map {
			exists($constraints{$_}) ? () : ($_ => $value->{$_})
		} keys %$value;
		
		my $explain = $slurpy->validate_explain(\%tmp, '$slurpy');
		return [
			sprintf('"%s" requires the hashref of additional key/value pairs to conform to "%s"', $type, $slurpy),
			@$explain,
		] if $explain;
	}
	else
	{
		for my $k (sort keys %$value)
		{
			return [
				sprintf('"%s" does not allow key %s to appear in hash', $type, B::perlstring($k))
			] unless exists $constraints{$k};
		}
	}
	
	return;
}

my $label_counter = 0;
our ($keycheck_counter, @KEYCHECK) = -1;
sub __coercion_generator
{
	my $slurpy = ref($_[-1]) eq q(HASH) ? pop(@_)->{slurpy} : undef;
	my ($parent, $child, %dict) = @_;
	my $C = "Type::Coercion"->new(type_constraint => $child);
	
	my $all_inlinable = 1;
	for my $tc (values %dict)
	{
		$all_inlinable = 0 if !$tc->can_be_inlined;
		$all_inlinable = 0 if $tc->has_coercion && !$tc->coercion->can_be_inlined;
		last if!$all_inlinable;
	}
	$all_inlinable = 0 if $slurpy && !$slurpy->can_be_inlined;
	$all_inlinable = 0 if $slurpy && $slurpy->has_coercion && !$slurpy->coercion->can_be_inlined;
	
	if ($all_inlinable)
	{
		$C->add_type_coercions($parent => Types::Standard::Stringable {
			require B;
			
			my $keycheck = join "|", map quotemeta, sort { length($b) <=> length($a) or $a cmp $b } keys %dict;
			$keycheck = $KEYCHECK[++$keycheck_counter] = qr{^($keycheck)$}ms; # regexp for legal keys
			
			my $label = sprintf("DICTLABEL%d", ++$label_counter);
			my @code;
			push @code, 'do { my ($orig, $return_orig, %tmp, %new) = ($_, 0);';
			push @code,       "$label: {";
			if ($slurpy)
			{
				push @code, sprintf('my $slurped = +{ map +($_=~$%s::KEYCHECK[%d])?():($_=>$orig->{$_}), keys %%$orig };', __PACKAGE__, $keycheck_counter);
				if ($slurpy->has_coercion)
				{
					push @code, sprintf('my $coerced = %s;', $slurpy->coercion->inline_coercion('$slurped'));
					push @code, sprintf('((%s)&&(%s))?(%%new=%%$coerced):(($return_orig = 1), last %s);', $_hash->inline_check('$coerced'), $slurpy->inline_check('$coerced'), $label);
				}
				else
				{
					push @code, sprintf('(%s)?(%%new=%%$slurped):(($return_orig = 1), last %s);', $slurpy->inline_check('$slurped'), $label);
				}
			}
			else
			{
				push @code, sprintf('($_ =~ $%s::KEYCHECK[%d])||(($return_orig = 1), last %s) for sort keys %%$orig;', __PACKAGE__, $keycheck_counter, $label);
			}
			for my $k (keys %dict)
			{
				my $ct = $dict{$k};
				my $ct_coerce   = $ct->has_coercion;
				my $ct_optional = $ct->is_a_type_of(Types::Standard::Optional);
				my $K = B::perlstring($k);
				
				push @code, "if (exists \$orig->{$K}) {" if $ct_optional;
				if ($ct_coerce)
				{
					push @code, sprintf('%%tmp = (); $tmp{x} = %s;', $ct->coercion->inline_coercion("\$orig->{$K}"));
					push @code, sprintf(
#						$ct_optional
#							? 'if (%s) { $new{%s}=$tmp{x} }'
#							:
						'if (%s) { $new{%s}=$tmp{x} } else { $return_orig = 1; last %s }',
						$ct->inline_check('$tmp{x}'),
						$K,
						$label,
					);
				}
				else
				{
					push @code, sprintf(
#						$ct_optional
#							? 'if (%s) { $new{%s}=$orig->{%s} }'
#							:
						'if (%s) { $new{%s}=$orig->{%s} } else { $return_orig = 1; last %s }',
						$ct->inline_check("\$orig->{$K}"),
						$K,
						$K,
						$label,
					);
				}
				push @code, '}' if $ct_optional;
			}
			push @code,       '}';
			push @code,    '$return_orig ? $orig : \\%new';
			push @code, '}';
			#warn "CODE:: @code";
			"@code";
		});
	}
	
	else
	{
		$C->add_type_coercions(
			$parent => sub {
				my $value = @_ ? $_[0] : $_;
				my %new;
				
				if ($slurpy)
				{
					my %slurped = map exists($dict{$_}) ? () : ($_ => $value->{$_}), keys %$value;
					
					if ($slurpy->check(\%slurped))
					{
						%new = %slurped;
					}
					elsif ($slurpy->has_coercion)
					{
						my $coerced = $slurpy->coerce(\%slurped);
						$slurpy->check($coerced) ? (%new = %$coerced) : (return $value);
					}
					else
					{
						return $value;
					}
				}
				else
				{
					for my $k (keys %$value)
					{
						return $value unless exists $dict{$k};
					}
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
					elsif (exists $value->{$k})
					{
						return $value;
					}
					
					if (@accept)
					{
						$new{$k} = $accept[0];
					}
					elsif (not $ct->is_a_type_of(Types::Standard::Optional))
					{
						return $value;
					}
				}
				
				return \%new;
			},
		);
	}
	
	return $C;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Standard::Dict - internals for the Types::Standard Dict type constraint

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

