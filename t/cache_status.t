use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: Cache-Status header off by default
--- config
    location = /static {
        immutable on;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
!Cache-Status


=== TEST 2: Cache-Status header when enabled (RFC 9211)
--- config
    location = /static {
        immutable on;
        immutable_cache_status on;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
Cache-Status: "nginx/immutable"; hit; ttl=31536000


=== TEST 3: Cache-Status header explicitly disabled
--- config
    location = /static {
        immutable on;
        immutable_cache_status off;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
!Cache-Status


=== TEST 4: Cache-Status inheritance from server level
--- config
    immutable_cache_status on;

    location = /static {
        immutable on;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
Cache-Status: "nginx/immutable"; hit; ttl=31536000


=== TEST 5: Cache-Status without immutable does nothing
--- config
    location = /static {
        immutable_cache_status on;
        return 200 "hello world\n";
    }
--- request
    GET /static
--- response_body
hello world
--- response_headers
!Cache-Control
!Cache-Status
