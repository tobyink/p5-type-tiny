use Test::Spellunker;
load_dictionary("$ENV{HOME}/perl5/stopwords.txt");
all_pod_files_spelling_ok();
