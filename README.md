# ngx_immutable

[![Build Status](https://travis-ci.org/GetPageSpeed/ngx_immutable.svg?branch=master)](https://travis-ci.org/GetPageSpeed/ngx_immutable)
[![Coverity Scan](https://img.shields.io/coverity/scan/GetPageSpeed-ngx_immutable)](https://scan.coverity.com/projects/GetPageSpeed-ngx_immutable)
[![Buy Me a Coffee](https://img.shields.io/badge/dynamic/json?color=blue&label=Buy%20me%20a%20Coffee&prefix=%23&query=next_time_total&url=https%3A%2F%2Fwww.getpagespeed.com%2Fbuymeacoffee.json&logo=buymeacoffee)](https://www.buymeacoffee.com/dvershinin)

This tiny NGINX module can help improve caching of your public static assets, by setting far future expiration with `immutable` attribute.

## Intended audience

Websites and frameworks which rely on the cache-busting pattern:

* static resources include version/hashes in their URLs, while never modifying the resources
* when necessary, updating the resources with newer versions that have new version-numbers/hashes,
so that their URLs are different

Popular frameworks which use cache-busting:

* Magento 2
* Include your own here!

## Synopsis

```nginx
http {
    server {
        location /static/ {
            immutable on;
        }
    }
}
```

will yield the following HTTP headers:

```
...
Cache-Control: public,max-age=31536000,stale-while-revalidate=31536000,stale-if-error=31536000,immutable
Expires: Thu, 31 Dec 2037 23:55:55 GMT
...
```

How it's different to `expires max;`:

* Sets `immutable` attribute, e.g. `Cache-Control: public,max-age=31536000,immutable` for improved caching.
That is 1 year and not 10 years, see why below.
* Sends `Expires` only when it's really necessary, e.g. when a client is requesting resources over `HTTP/1.0`
* Sets `public` attribute to ensure the assets can be cached by public caches, which is typically a desired thing.

Due to the [lacking support of `immutable`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#browser_compatibility) in Chromium-based browsers,
we also add `stale-while-revalidate=31536000,stale-if-error=31536000` which helps to improve cache hit-ratio in edge cases.
Use of these directives allows serving cached responses beyond their cache lifetime, which is forever in case of immutable resources.

Thus, in most cases, `immutable on;` can be used as a better alternative to `expires max;` to implement the cache-busting pattern.

## Directives

### immutable

**Syntax:** `immutable on | off;`

**Default:** `immutable off;`

**Context:** `http`, `server`, `location`

Enables or disables immutable caching headers for the location.

### immutable_types

**Syntax:** `immutable_types mime-type ...;`

**Default:** none (applies to all MIME types)

**Context:** `http`, `server`, `location`

Restricts immutable headers to responses with the specified MIME types. By default (when this directive is not used), immutable headers are applied to all MIME types.

```nginx
location /static/ {
    immutable on;
    immutable_types text/css application/javascript image/png image/jpeg;
}
```

### immutable_cache_status

**Syntax:** `immutable_cache_status on | off;`

**Default:** `immutable_cache_status off;`

**Context:** `http`, `server`, `location`

Enables the [RFC 9211](https://datatracker.ietf.org/doc/rfc9211/) `Cache-Status` header for debugging and observability. When enabled, responses include:

```
Cache-Status: "nginx/immutable"; hit; ttl=31536000
```

This header helps debug caching behavior across multi-layer caching architectures (NGINX -> CDN -> Browser). Each cache layer can append its own status, creating a chain like:

```
Cache-Status: "nginx/immutable"; hit; ttl=31536000, "cloudflare"; fwd=uri-miss; stored
```

Example configuration:

```nginx
location /static/ {
    immutable on;
    immutable_cache_status on;
}
```

### Why 31536000 seconds (1 year?)

The [RFC](https://www.ietf.org/rfc/rfc2616.txt) defines to use one year to make a response as "never expires":

> To mark a response as “never expires,” an origin server sends an
> Expires date approximately one year from the time the response is
> sent. HTTP/1.1 servers SHOULD NOT send Expires dates more than one
> year in the future.

More details in [the article](https://ashton.codes/set-cache-control-max-age-1-year/).

## Ubuntu and Debian packages

It's easy to install the module package for these operating systems.

`ngx_immutable` is part of the APT NGINX Extras collection, so you can install
it alongside [any modules](https://apt-nginx-extras.getpagespeed.com/modules/),
including Brotli.

First, [set up the repository](https://apt-nginx-extras.getpagespeed.com/apt-setup/), then:

```bash
sudo apt-get update
sudo apt-get install nginx-module-immutable
```

## Installation for RPM-based systems

GetPageSpeed provides packaging of the `nginx-module-immutable` in its repositories, as part of its [NGINX Extras](https://nginx-extras.getpagespeed.com/) package collection.

The following operating systems are supported:

* Red Hat Enterprise Linux 6, 7, 8, 9
* CentOS 6, 7, 8, 9
* AlmaLinux 8, 9
* Rocky Linux 8, 9
* Amazon Linux 2
* Fedora Linux, the 2 most recent releases

The installation requires a [subscription](https://www.getpagespeed.com/repo-subscribe) for all the operating systems listed, except Fedora Linux, for which it is free.

### How to install

For any OS listed above, installation steps are the same:

```bash
sudo yum -y install https://extras.getpagespeed.com/release-latest.rpm
sudo yum -y install nginx-module-immutable
```

Follow the installation prompt to import GPG public key that is used for verifying packages.

Then add the following at the top of your `/etc/nginx/nginx.conf`:

```nginx
load_module modules/ngx_http_immutable_module.so;
```

## Example: Magento 2 production configuration

Provided that your store runs in production mode, you have already compiled all the assets.
This [sample config](https://github.com/magento/magento2/blob/2.3.4/nginx.conf.sample#L103-L134) can be optimized to:

```nginx
location /static/ {
    immutable on;

    # Remove signature of the static files that is used to overcome the browser cache
    location ~ ^/static/version {
        rewrite ^/static/(version\d*/)?(.*)$ /static/$2 last;
    }

    location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2|json)$ {
        add_header X-Frame-Options "SAMEORIGIN";
    }
    location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
        add_header Cache-Control "no-store";
        add_header X-Frame-Options "SAMEORIGIN";
        immutable off;
    }
    add_header X-Frame-Options "SAMEORIGIN";
}
```

When used together with [`ngx_security_headers`](https://github.com/GetPageSpeed/ngx_security_headers), it can be simplified further:

```nginx
security_headers on;

location /static/ {
    immutable on;


    location ~ ^/static/version {
        rewrite ^/static/(version\d*/)?(.*)$ /static/$2 last;
    }

    location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
        add_header Cache-Control "no-store";
        immutable off;
    }
}
```
