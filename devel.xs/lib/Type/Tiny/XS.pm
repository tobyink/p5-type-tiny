package Type::Tiny::XS;

eval { require Mouse };
require Type::Tiny;

eval {
	package Type::Tiny;
	
	require Class::XSAccessor;
	'Class::XSAccessor'->VERSION('1.17');
	'Class::XSAccessor'->import(
		replace => 1,
		getters => {
			name                     => 'name',
			parent                   => 'parent',
			message                  => 'message',
			library                  => 'library',
			inlined                  => 'inlined',
			inline_generator         => 'inline_generator',
			coercion_generator       => 'coercion_generator',
			parameters               => 'parameters',
			deep_explanation         => 'deep_explanation',
		},
		def_predicate => {
			has_message              => 'message',
		},
		ex_predicate => {
			has_parent               => 'parent',
			has_library              => 'library',
			has_inlined              => 'inlined',
			has_constraint_generator => 'constraint_generator',
			has_inline_generator     => 'inline_generator',
			has_coercion_generator   => 'coercion_generator',
			has_parameters           => 'parameters',
			has_deep_explanation     => 'deep_explanation',
		},
	);
};

# TODO: Type::Tiny::check

1;
