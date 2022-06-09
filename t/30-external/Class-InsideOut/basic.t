=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Class::InsideOut>.

=head1 DEPENDENCIES

Test is skipped if Class::InsideOut 1.13 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on C<< t/14_accessor_hooks.t >> from the Class::InsideOut test suite,
by David Golden.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by David Golden, Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::Requires { "Class::InsideOut" => 1.13 };
use Test::More;

BEGIN {
	package Object::HookedTT;
	
	use Class::InsideOut ':std';
	use Types::Standard -types;
	
	# $_ has the first argument in it for convenience
	public integer => my %integer, { set_hook => Int };
	
	# first argument is also available directly
	public word => my %word, { set_hook => StrMatch[qr/\A\w+\z/] };
	
	# Changing $_ changes what gets stored
	my $UC = (StrMatch[qr/\A[A-Z]+\z/])->plus_coercions(Str, q{uc $_});
	public uppercase => my %uppercase, {
		set_hook => sub {
			$_ = $UC->coercion->($_)
		},
	};
	
	# Full @_ is available, but only first gets stored
	public list => my %list, {
		set_hook => sub { $_ = ArrayRef->check($_) ? $_ : [ @_ ] },
		get_hook => sub { @$_ },
	};
	
	public reverser => my %reverser, {
		set_hook => sub { $_ = ArrayRef->check($_) ? $_ : [ @_ ] },
		get_hook => sub {  reverse @$_ }
	};
	
	public write_only => my %only_only, {
		get_hook => sub { die "is write-only\n" }
	};
	
	sub new {
		register( bless {}, shift );
	}
};

#--------------------------------------------------------------------------#

my $class = "Object::HookedTT";
my $properties = {
	$class => {
		integer    => "public",
		uppercase  => "public",
		word       => "public",
		list       => "public",
		reverser   => "public",
		write_only => "public",
	},
};

my ($o, @got, $got);

#--------------------------------------------------------------------------#

is_deeply(
	Class::InsideOut::_properties( $class ),
	$properties,
	"$class has/inherited its expected properties",
);

ok(
	($o = $class->new()) && $o->isa($class),
	"Creating a $class object",
);

#--------------------------------------------------------------------------#

eval { $o->integer(3.14) };
my $err = $@;
like(
	$err,
	'/integer\(\) Value "3.14" did not pass type constraint "Int"/i',
	"integer(3.14) dies",
);

eval { $o->integer(42) };
is(
	$@,
	q{},
	"integer(42) lives",
);
is(
	$o->integer,
	42,
	"integer() == 42",
);

#--------------------------------------------------------------------------#

eval { $o->word("^^^^") };
like(
	$@,
	'/word\(\) value "\^\^\^\^" did not pass type constraint/i',
	"word(^^^^) dies",
);
eval { $o->word("apple") };
is(
	$@,
	q{},
	"word(apple) lives",
);
is(
	$o->word,
	'apple',
	"word() eq 'apple'",
);

#--------------------------------------------------------------------------#

eval { $o->uppercase("banana") };
is(
	$@,
	q{},
	"uppercase(banana) lives",
);
is(
	$o->uppercase,
	'BANANA',
	"uppercase() eq 'BANANA'",
);

#--------------------------------------------------------------------------#

# list(@array)

eval { $o->list(qw(foo bar bam)) };
is(
	$@,
	q{},
	"list(qw(foo bar bam)) lives",
);
is_deeply(
	[ $o->list ],
	[qw(foo bar bam)],
	"list() gives qw(foo bar bam)",
);

# list(\@array)

eval { $o->list( [qw(foo bar bam)] ) };
is(
	$@,
	q{},
	"list( [qw(foo bar bam)] ) lives",
);
is_deeply(
	[ $o->list ],
	[qw(foo bar bam)],
	"list() gives qw(foo bar bam)",
);

#--------------------------------------------------------------------------#

eval { $o->reverser(qw(foo bar bam)) };
is(
	$@,
	q{},
	"reverser(qw(foo bar bam)) lives",
);

# reverser in list context
@got = $o->reverser;
is_deeply(
	\@got,
	[qw(bam bar foo)],
	"reverser() in list context gives qw(bam bar foo)",
);

# reverser in scalar context
$got = $o->reverser;
is(
	$got,
	'mabraboof',
	"reverser() in scalar context gives mabraboof",
);

#--------------------------------------------------------------------------#

eval { $o->write_only( 23 ) };
is(
	$@,
	q{},
	"write_only lives on write",
);

eval { $got = $o->write_only() };
like(
	$@,
	'/write_only\(\) is write-only at/i',
	"write only dies on write (and was caught)",
);

done_testing;
