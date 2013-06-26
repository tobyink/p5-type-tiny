package Type::Parser;

use strict;
use warnings;

sub _croak ($;@) { require Type::Exception; goto \&Type::Exception::croak }

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

# Token types
# 
sub TYPE      () { "TYPE" };
sub QUOTELIKE () { "QUOTELIKE" };
sub STRING    () { "STRING" };
sub CLASS     () { "CLASS" };
sub L_BRACKET () { "L_BRACKET" };
sub R_BRACKET () { "R_BRACKET" };
sub COMMA     () { "COMMA" };
sub SLURPY    () { "SLURPY" };
sub UNION     () { "UNION" };
sub INTERSECT () { "INTERSECT" };
sub NOT       () { "NOT" };
sub L_PAREN   () { "L_PAREN" };
sub R_PAREN   () { "R_PAREN" };
sub MYSTERY   () { "MYSTERY" };

our @EXPORT_OK = qw( tokens parse eval_type _std_eval );
use base "Exporter::TypeTiny";

Evaluate: {
	
	sub eval_type
	{
		my ($str, $reg) = @_;
		my $parsed = parse($str);
		return _eval_type($parsed, $reg);
	}
	
	my $std;
	sub _std_eval
	{
		require Type::Registry;
		unless ($std)
		{
			$std = "Type::Registry"->new;
			$std->add_types(-Standard);
		}
		eval_type($_[0], $std);
	}
	
	sub _eval_type
	{
		my ($node, $reg) = @_;
		
		$node = _simplify_expression($node);
		
		if ($node->{type} eq "list")
		{
			return map _eval_type($_, $reg), @{$node->{list}};
		}
		
		if ($node->{type} eq "union")
		{
			require Type::Tiny::Union;
			return "Type::Tiny::Union"->new(
				type_constraints => [ map _eval_type($_, $reg), @{$node->{union}} ],
			);
		}
		
		if ($node->{type} eq "intersect")
		{
			require Type::Tiny::Intersection;
			return "Type::Tiny::Intersection"->new(
				type_constraints => [ map _eval_type($_, $reg), @{$node->{intersect}} ],
			);
		}
		
		if ($node->{type} eq "slurpy")
		{
			return +{ slurpy => _eval_type($node->{of}, $reg) };
		}
		
		if ($node->{type} eq "complement")
		{
			return _eval_type($node->{of}, $reg)->complementary_type;
		}
		
		if ($node->{type} eq "parameterized")
		{
			return _eval_type($node->{base}, $reg) unless $node->{params};
			return _eval_type($node->{base}, $reg)->parameterize(_eval_type($node->{params}, $reg));
		}
		
		if ($node->{type} eq "primary" and $node->{token}->type eq CLASS)
		{
			my $class = substr($node->{token}->spelling, 0, length($node->{token}->spelling) - 2);
			require Type::Tiny::Class;
			return "Type::Tiny::Class"->new(class => $class);
		}
		
		if ($node->{type} eq "primary" and $node->{token}->type eq QUOTELIKE)
		{
			return eval($node->{token}->spelling); #ARGH
		}
		
		if ($node->{type} eq "primary" and $node->{token}->type eq STRING)
		{
			return $node->{token}->spelling;
		}
		
		if ($node->{type} eq "primary" and $node->{token}->type eq TYPE)
		{
			my $t = $node->{token}->spelling;
			if ($t =~ /^(.+)::(\w+)$/)
			{
				my $library = $1; $t = $2;
				eval "require $library;";
				return $library->get_type($t);
			}
			return $reg->simple_lookup($t);
		}
	}
	
	sub _simplify_expression
	{
		my $expr = shift;
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq COMMA)
		{
			return _simplify("list", COMMA, $expr);
		}
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq UNION)
		{
			return _simplify("union", UNION, $expr);
		}
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq INTERSECT)
		{
			return _simplify("intersect", INTERSECT, $expr);
		}
		
		return $expr;
	}
	
	sub _simplify
	{
		my $type = shift;
		my $op   = shift;
		
		my @list;
		for my $expr ($_[0]{lhs}, $_[0]{rhs})
		{
			if ($expr->{type} eq "expression" and $expr->{op}[0] eq $op)
			{
				my $simple = _simplify($type, $op, $expr);
				push @list, @{ $simple->{$type} };
			}
			else
			{
				push @list, $expr;
			}
		}
		
		return { type => $type, $type => \@list };
	}
}

Parsing: {
	our $tokens;
	
	my %precedence = (
		+COMMA     => 1,
		+UNION     => 2,
		+INTERSECT => 3,
		+NOT       => 4,
	);
	
	sub _parse_primary
	{
		$tokens->assert_not_empty;
		
		if ($tokens->peek(0)->type eq NOT)
		{
			$tokens->eat(NOT);
			$tokens->assert_not_empty;
			return {
				type  => "complement",
				of    => _parse_primary(),
			};
		}
		
		if ($tokens->peek(0)->type eq SLURPY)
		{
			$tokens->eat(SLURPY);
			$tokens->assert_not_empty;
			return {
				type  => "slurpy",
				of    => _parse_primary(),
			};
		}
		
		if ($tokens->peek(0)->type eq L_PAREN)
		{
			$tokens->eat(L_PAREN);
			my $r = _parse_expression();
			$tokens->eat(R_PAREN);
			return $r;
		}
		
		if ($tokens->peek(1) and $tokens->peek(0)->type eq TYPE and $tokens->peek(1)->type eq L_BRACKET)
		{
			my $base = { type  => "primary", token => $tokens->eat(TYPE) };
			$tokens->eat(L_BRACKET);
			$tokens->assert_not_empty;
			
			my $params = undef;
			if ($tokens->peek(0)->type eq R_BRACKET)
			{
				$tokens->eat(R_BRACKET);
			}
			else
			{
				$params = _parse_expression();
				$params = { type => "list", list => [$params] } unless $params->{type} eq "list";
				$tokens->eat(R_BRACKET);
			}
			return {
				type   => "parameterized",
				base   => $base,
				params => $params,
			};
		}
		
		my $type = $tokens->peek(0)->type;
		if ($type eq Type::Parser::TYPE
		or  $type eq Type::Parser::QUOTELIKE
		or  $type eq Type::Parser::STRING
		or  $type eq Type::Parser::CLASS)
		{
			return { type  => "primary", token => $tokens->eat };
		}
		
		_croak("Unexpected token in primary type expression; got '%s'", $tokens->peek(0)->spelling);
	}
	
	sub _parse_expression_1
	{
		my ($lhs, $min_p) = @_;
		while (!$tokens->empty and exists $precedence{$tokens->peek(0)->type} and $precedence{$tokens->peek(0)->type} >= $min_p)
		{
			my $op  = $tokens->eat;
			my $rhs = _parse_primary();
			
			while (!$tokens->empty and exists $precedence{$tokens->peek(0)->type} and $precedence{$tokens->peek(0)->type} > $precedence{$op->type})
			{
				my $lookahead = $tokens->peek(0);
				$rhs = _parse_expression_1($rhs, $precedence{$lookahead->type});
			}
			
			$lhs = {
				type => "expression",
				op   => $op,
				lhs  => $lhs,
				rhs  => $rhs,
			};
		}
		return $lhs;
	}
	
	sub _parse_expression
	{
		return _parse_expression_1(_parse_primary(), 0);
	}
	
	sub parse
	{
		local $tokens = "Type::Parser::TokenStream"->new(remaining => $_[0]);
		return _parse_expression();
	}
}

{
	package # hide from CPAN
	Type::Parser::Token;
	sub type     { $_[0][0] }
	sub spelling { $_[0][1] }
}

{
	package # hide from CPAN
	Type::Parser::TokenStream;
	
	use Text::Balanced qw(extract_quotelike);
	
	sub new
	{
		my $class = shift;
		bless { stack => [], done => [], @_ }, $class;
	}
	
	sub peek
	{
		my $self  = shift;
		my $ahead = $_[0];
		
		while ($self->_stack_size <= $ahead and length $self->{remaining})
		{
			$self->_stack_extend;
		}
		
		my @tokens = grep ref, @{ $self->{stack} };
		return $tokens[$ahead];
	}
	
	sub empty
	{
		my $self = shift;
		not $self->peek(0);
	}
	
	sub eat
	{
		my $self = shift;
		$self->_stack_extend unless $self->_stack_size;
		my $r;
		while (defined(my $item = shift @{$self->{stack}}))
		{
			push @{ $self->{done} }, $item;
			if (ref $item)
			{
				$r = $item;
				last;
			}
		}
		
		if (@_ and $_[0] ne $r->type)
		{
			unshift @{$self->{stack}}, pop @{$self->{done}};
			Type::Parser::_croak("Expected $_[0]; got ".$r->type);
		}
		
		return $r;
	}
	
	sub assert_not_empty
	{
		my $self = shift;
		Type::Parser::_croak("Expected token; got empty string") if $self->empty;
	}
	
	sub _stack_size
	{
		my $self = shift;
		scalar grep ref, @{ $self->{stack} };
	}
	
	sub _stack_extend
	{
		my $self = shift;
		push @{ $self->{stack} }, $self->_read_token;
		my ($space) = ($self->{remaining} =~ m/^([\s\n\r]*)/sm);
		return unless length $space;
		push @{ $self->{stack} }, $space;
		substr($self->{remaining}, 0, length $space) = "";
	}
	
	sub remainder
	{
		my $self = shift;
		return join "",
			map { ref($_) ? $_->spelling : $_ }
			(@{$self->{stack}}, $self->{remaining})
	}
	
	my %punctuation = (
		'['       => bless([ Type::Parser::L_BRACKET, "[" ], "Type::Parser::Token"),
		']'       => bless([ Type::Parser::R_BRACKET, "]" ], "Type::Parser::Token"),
		'('       => bless([ Type::Parser::L_PAREN,   "[" ], "Type::Parser::Token"),
		')'       => bless([ Type::Parser::R_PAREN,   "]" ], "Type::Parser::Token"),
		','       => bless([ Type::Parser::COMMA,     "," ], "Type::Parser::Token"),
		'=>'      => bless([ Type::Parser::COMMA,     "=>" ], "Type::Parser::Token"),
		'slurpy'  => bless([ Type::Parser::SLURPY,    "slurpy" ], "Type::Parser::Token"),
		'|'       => bless([ Type::Parser::UNION,     "|" ], "Type::Parser::Token"),
		'&'       => bless([ Type::Parser::INTERSECT, "&" ], "Type::Parser::Token"),
		'~'       => bless([ Type::Parser::NOT,       "~" ], "Type::Parser::Token"),
	);
	
	sub _read_token
	{
		my $self = shift;
		
		return if $self->{remaining} eq "";
		
		# Punctuation
		# 
		
		if ($self->{remaining} =~ /^( => | [()\]\[|&~,] )/xsm)
		{
			my $spelling = $1;
			substr($self->{remaining}, 0, length $spelling) = "";
			return $punctuation{$spelling};
		}
		
		if (my $quotelike = extract_quotelike $self->{remaining})
		{
			return bless([ Type::Parser::QUOTELIKE, $quotelike ], "Type::Parser::Token"),;
		}
		
		if ($self->{remaining} =~ /^([\w:]+)/sm)
		{
			my $spelling = $1;
			substr($self->{remaining}, 0, length $spelling) = "";
			
			if ($spelling =~ /::$/sm)
			{
				return bless([ Type::Parser::CLASS, $spelling ], "Type::Parser::Token"),;
			}
			elsif ($self->{remaining} =~ /^\s*=>/sm) # peek ahead
			{
				return bless([ Type::Parser::STRING, $spelling ], "Type::Parser::Token"),;
			}
			elsif ($spelling eq "slurpy")
			{
				return $punctuation{$spelling};
			}
			
			return bless([ Type::Parser::TYPE, $spelling ], "Type::Parser::Token");
		}
		
		my $rest = $self->{remaining};
		$self->{remaining} = "";
		return bless([ Type::Parser::MYSTERY, $rest ], "Type::Parser::Token");
	}	
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Parser - parse type constraint strings

=head1 SYNOPSIS

 use v5.10;
 use strict;
 use warnings;
 
 use Type::Parser qw( eval_type );
 use Type::Registry;
 
 my $reg = Type::Registry->for_me;
 $reg->add_types("Types::Standard");
 
 my $type = eval_type("Int | ArrayRef[Int]", $reg);
 
 $type->check(10);        # true
 $type->check([1..4]);    # true
 $type->check({foo=>1});  # false

=head1 DESCRIPTION

Generally speaking, you probably don't want to be using this module directly.
Instead use the C<< lookup >> method from L<Type::Registry> which wraps it.

=head2 Functions

=over

=item C<< tokens($string) >>

Tokenize the type constraint string; returns a list of tokens.

=item C<< parse($string) >>, C<< parse($arrayref_of_tokens) >>

Parse the type constraint string into something like an AST.

=item C<< eval_type($string, $registry) >>, C<< eval_type($arrayref_of_tokens, $registry) >>

Compile the type constraint string into a L<Type::Tiny> object.

=back

=head2 Constants

The following constants correspond to values returned by C<< $token->type >>.

=over

=item C<< TYPE >>

=item C<< QUOTELIKE >>

=item C<< STRING >>

=item C<< CLASS >>

=item C<< L_BRACKET >>

=item C<< R_BRACKET >>

=item C<< COMMA >>

=item C<< SLURPY >>

=item C<< UNION >>

=item C<< INTERSECT >>

=item C<< NOT >>

=item C<< L_PAREN >>

=item C<< R_PAREN >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Type-Tiny>.

=head1 SEE ALSO

L<Type::Registry>.

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

