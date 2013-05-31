package Type::Parser;

use strict;
use warnings;

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

use Carp qw(croak confess);
use Text::Balanced qw(extract_quotelike);

our @EXPORT_OK = qw( parse eval_type );
use base "Exporter::TypeTiny";

Evaluate: {
	
	sub eval_type
	{
		my ($str, $reg) = @_;
		my $parsed = parse($str);
		return _eval_type($parsed, $reg);
	}
	
	sub _eval_type
	{
		my ($node, $reg) = @_;
		
		$node = simplify_expression($node);
		
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
			return eval($node->{token}->spelling);
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
	
	sub simplify_expression
	{
		my $expr = shift;
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq COMMA)
		{
			return simplify("list", COMMA, $expr);
		}
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq UNION)
		{
			return simplify("union", UNION, $expr);
		}
		
		if ($expr->{type} eq "expression" and $expr->{op}[0] eq INTERSECT)
		{
			return simplify("intersect", INTERSECT, $expr);
		}
		
		return $expr;
	}
	
	sub simplify
	{
		my $type = shift;
		my $op   = shift;
		
		my @list;
		for my $expr ($_[0]{lhs}, $_[0]{rhs})
		{
			if ($expr->{type} eq "expression" and $expr->{op}[0] eq $op)
			{
				my $simple = simplify($type, $op, $expr);
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
	our @tokens;
	
	my %precedence = (
		+COMMA     => 1,
		+UNION     => 2,
		+INTERSECT => 3,
		+NOT       => 4,
	);
	
	sub parse_primary
	{
		confess "ARGH" unless @tokens;
		if ($tokens[0]->type eq NOT)
		{
			shift @tokens;
			return {
				type  => "complement",
				of    => parse_primary(),
			};
		}
		
		if ($tokens[0]->type eq SLURPY)
		{
			shift @tokens;
			return {
				type  => "slurpy",
				of    => parse_primary(),
			};
		}
		
		if (@tokens > 1 and $tokens[0]->type eq TYPE and $tokens[1]->type eq L_BRACKET)
		{
			my $base = { type  => "primary", token => shift @tokens };
			shift @tokens;
			my $params = undef;
			if ($tokens[0]->type eq R_BRACKET)
			{
				shift @tokens;
			}
			else
			{
				$params = parse_expression();
				$params = { type => "list", list => [$params] } unless $params->{type} eq "list";
				$tokens[0]->type eq R_BRACKET or die;
				shift @tokens;
			}
			return {
				type   => "parameterized",
				base   => $base,
				params => $params,
			};
		}
		
		if ($tokens[0]->is_primary)
		{
			return { type  => "primary", token => shift @tokens };
		}
		
		die;
	}
	
	sub parse_expression_1
	{
		my ($lhs, $min_p) = @_;
		while (@tokens and exists $precedence{$tokens[0]->type} and $precedence{$tokens[0]->type} >= $min_p)
		{
			my $op  = shift @tokens;
			my $rhs = parse_primary();
			
			while (@tokens and exists $precedence{$tokens[0]->type} and $precedence{$tokens[0]->type} > $precedence{$op->type})
			{
				my $lookahead = shift @tokens;
				$rhs = parse_expression_1($rhs, $precedence{$lookahead->type});
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
	
	sub parse_expression
	{
		return parse_expression_1(parse_primary(), 0);
	}
	
	sub parse
	{
		local @tokens = tokens($_[0]);
		return parse_expression();
	}
}

Tokenization: {
	our $str;
	
	sub tokens
	{
		local $str = shift;
		return @$str if ref $str;
		
		my @tokens;
		my $count;
		while (my $token = token())
		{
			die "ETOOBIG" if $count++ > 1000;
			push @tokens, $token;
		}
		return @tokens;
	}
	
	my %punctuation = (
		'['       => bless([ L_BRACKET, "[" ], "Type::Parser::Token"),
		']'       => bless([ R_BRACKET, "]" ], "Type::Parser::Token"),
		','       => bless([ COMMA,     "," ], "Type::Parser::Token"),
		'=>'      => bless([ COMMA,     "=>" ], "Type::Parser::Token"),
		'slurpy'  => bless([ SLURPY,    "slurpy" ], "Type::Parser::Token"),
		'|'       => bless([ UNION,     "|" ], "Type::Parser::Token"),
		'&'       => bless([ INTERSECT, "&" ], "Type::Parser::Token"),
		'~'       => bless([ NOT,       "~" ], "Type::Parser::Token"),
	);
	
	sub token
	{
		$str =~ s/^\s*//sm;
		
		return if $str eq "";
		
		# Punctuation
		# 
		
		if ($str =~ /^( slurpy | => | [\]\[|&~,] )/xsm)
		{
			my $spelling = $1;
			$str = substr($str, length $spelling);
			return $punctuation{$spelling};
		}
		
		if (my $quotelike = extract_quotelike $str)
		{
			return bless([ QUOTELIKE, $quotelike ], "Type::Parser::Token"),;
		}
		
		if ($str =~ /^([\w:]+)/sm)
		{
			my $spelling = $1;
			$str = substr($str, length $spelling);
			
			if ($spelling =~ /::$/sm)
			{
				return bless([ CLASS, $spelling ], "Type::Parser::Token"),;
			}
			elsif ($str =~ /\s*=>$/sm) # peek ahead
			{
				return bless([ STRING, $spelling ], "Type::Parser::Token"),;
			}
			
			return bless([ TYPE, $spelling ], "Type::Parser::Token"),;
		}
		
		croak "Unexpected token parsing type constraint; remaining '$str'";
	}
	
	{
		package Type::Parser::Token;
		
		sub is_primary
		{
			my $self = shift;
			return 1 if $self->[0] eq Type::Parser::TYPE;
			return 1 if $self->[0] eq Type::Parser::QUOTELIKE;
			return 1 if $self->[0] eq Type::Parser::STRING;
			return 1 if $self->[0] eq Type::Parser::CLASS;
			return;
		}
		
		sub type
		{
			return $_[0][0];
		}
		
		sub spelling
		{
			return $_[0][1];
		}
	}
}

1;
