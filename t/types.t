use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: immutable applies to all types by default (no immutable_types)
--- config
    location = /test.txt {
        immutable on;
        default_type text/plain;
        return 200 "hello world\n";
    }
--- request
    GET /test.txt
--- response_body
hello world
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 2: immutable_types restricts to matching type
--- config
    location = /test.js {
        immutable on;
        immutable_types application/javascript;
        default_type application/javascript;
        return 200 "js";
    }
--- request
    GET /test.js
--- response_body
js
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 3: immutable_types skips non-matching type
--- config
    location = /test.txt {
        immutable on;
        immutable_types application/javascript;
        default_type text/plain;
        return 200 "text";
    }
--- request
    GET /test.txt
--- response_body
text
--- response_headers
!Cache-Control


=== TEST 4: immutable_types with multiple types - first type matches
--- config
    location = /test.css {
        immutable on;
        immutable_types text/css application/javascript;
        default_type text/css;
        return 200 "css";
    }
--- request
    GET /test.css
--- response_body
css
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 5: immutable_types with multiple types - second type matches
--- config
    location = /test.js {
        immutable on;
        immutable_types text/css application/javascript;
        default_type application/javascript;
        return 200 "js";
    }
--- request
    GET /test.js
--- response_body
js
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
