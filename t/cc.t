use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: immutable loc
--- config
    location = /static {
        immutable on;
        # immutable_types *;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable

