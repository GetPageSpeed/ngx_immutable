use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: immutable applies to all types by default
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


=== TEST 2: immutable_types restricts to specific types
--- config
    location = /test.js {
        immutable on;
        immutable_types application/javascript;
        default_type application/javascript;
        return 200 "console.log('hello');\n";
    }
--- request
    GET /test.js
--- response_body
console.log('hello');
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 3: immutable_types skips non-matching types
--- config
    location = /test.txt {
        immutable on;
        immutable_types application/javascript;
        default_type text/plain;
        return 200 "hello world\n";
    }
--- request
    GET /test.txt
--- response_body
hello world
--- response_headers
!Cache-Control


=== TEST 4: immutable_types with multiple types
--- config
    location = /test.css {
        immutable on;
        immutable_types text/css application/javascript;
        default_type text/css;
        return 200 "body { color: red; }\n";
    }
--- request
    GET /test.css
--- response_body
body { color: red; }
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 5: immutable_types with wildcard
--- config
    location = /test.png {
        immutable on;
        immutable_types image/*;
        default_type image/png;
        return 200 "PNG";
    }
--- request
    GET /test.png
--- response_body
PNG
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 6: immutable_types inheritance
--- config
    immutable_types text/css application/javascript;

    location = /test.js {
        immutable on;
        default_type application/javascript;
        return 200 "js";
    }
--- request
    GET /test.js
--- response_body
js
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable


=== TEST 7: immutable_types with Cache-Status
--- config
    location = /test.js {
        immutable on;
        immutable_cache_status on;
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
Cache-Status: "nginx/immutable"; hit; ttl=31536000
