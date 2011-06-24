use inc::Module::Install;
name 'Plack-Middleware-Forward';
all_from 'lib/Plack/Middleware/Forward.pm';
readme_from 'lib/Plack/Middleware/Forward.pm';
readme_pod_from 'lib/Plack/Middleware/Forward.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
