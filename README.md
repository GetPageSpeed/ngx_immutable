# ngx_immutable

[![Build Status](https://travis-ci.org/GetPageSpeed/ngx_immutable.svg?branch=master)](https://travis-ci.org/GetPageSpeed/ngx_immutable)
[![Coverity Scan](https://img.shields.io/coverity/scan/GetPageSpeed-ngx_immutable)](https://scan.coverity.com/projects/GetPageSpeed-ngx_immutable)

This tiny NGINX module can help improve caching of your public static assets, by setting far future expiration with `immutable` attribute.

## Synopsis

```
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
Cache-Control: public,max-age=31536000,immutable
Expires: Thu, 31 Dec 2037 23:55:55 GMT 
...
```

How it's different to `expires max;`:

* Sets `immutable` attribute, e.g. `Cache-Control: public,max-age=31536000,immutable` for improved caching
* Sends `Expires` only when it's really necessary, e.g. when a client is requesting resources over `HTTP/1.0`
* Sets `public` attribute to ensure the assets can be cached by public caches, which is typically a desired thing.

Thus, in most cases, `immutable on;` can be used as a better alternative to `expires max;`.

## Installation 

### CentOS/RHEL 6, 7, 8; Amazon Linux 2; Fedora Linux

    sudo yum -y install https://extras.getpagespeed.com/release-latest.rpm
    sudo yum -y install nginx-module-immutable

Follow the installation prompt to import GPG public key that is used for verifying packages.

Then add the following at the top of your `/etc/nginx/nginx.conf`:

    load_module modules/ngx_http_immutable_module.so;

## Example: Magento 2 production configuration

Provided that your store runs in production mode, you have already compiled all the assets.
This [sample config](https://github.com/magento/magento2/blob/2.3.4/nginx.conf.sample#L103-L134) can be optimized to:

```
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

```
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