# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each() * 2 * blocks();

no_shuffle();

run_tests();

__DATA__

=== TEST 1: immutable_types with matching content type
When immutable_types is specified and content type matches, Cache-Control should be set
--- config
    location = /test.js {
        immutable on;
        immutable_types application/javascript;
        default_type application/javascript;
        return 200 "console.log('hello');";
    }
--- request
    GET /test.js
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable

=== TEST 2: immutable_types with non-matching content type
When immutable_types is specified and content type does NOT match, no Cache-Control should be set
--- config
    location = /test.txt {
        immutable on;
        immutable_types application/javascript;
        default_type text/plain;
        return 200 "plain text";
    }
--- request
    GET /test.txt
--- response_headers
!Cache-Control

=== TEST 3: immutable without immutable_types applies to all types
When no immutable_types is specified, immutable should apply to all content types
--- config
    location = /test.html {
        immutable on;
        default_type text/html;
        return 200 "<html></html>";
    }
--- request
    GET /test.html
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable

=== TEST 4: immutable_types with multiple types
When multiple types are specified, matching any should work
--- config
    location = /test.css {
        immutable on;
        immutable_types application/javascript text/css image/png;
        default_type text/css;
        return 200 "body {}";
    }
--- request
    GET /test.css
--- response_headers
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
