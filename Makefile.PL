use inc::Module::Package 'RDF:tobyink 0.012';

include "Test::Requires";
include "Test::Fatal";
include "Try::Tiny";

dynamic_config;

if ($] < 5.007003) {
	requires "Scalar::Util"   => "1.13";
	requires "Text::Balanced" => "1.95";
}
