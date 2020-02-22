use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: dying on bad config
--- http_config
    immutable bad;
--- config
--- must_die
--- error_log
it must be "on" or "off"