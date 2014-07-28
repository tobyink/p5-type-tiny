use Test::More;
eval { require Test::Synopsis }
	or plan(skip_all => "Test::Synopsis required for testing");
eval { require Test::Tabs }
	or plan(skip_all => "Test::Tabs required for testing");

Test::Synopsis::synopsis_ok(
	Test::Tabs::_all_perl_files(qw/ lib /)
);

done_testing;
