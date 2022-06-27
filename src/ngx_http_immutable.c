/*
 * Copyright (c) 2019 Danila Vershinin ( https://www.getpagespeed.com )
 */


#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>


typedef struct {
    ngx_flag_t                 enable;

    ngx_hash_t                 types;
    ngx_array_t                *types_keys;

} ngx_http_immutable_loc_conf_t;



static ngx_int_t ngx_http_immutable_filter(ngx_http_request_t *r);
static void *ngx_http_immutable_create_loc_conf(ngx_conf_t *cf);
static char *ngx_http_immutable_merge_loc_conf(ngx_conf_t *cf,
                                                      void *parent, void *child);
static ngx_int_t ngx_http_immutable_init(ngx_conf_t *cf);

ngx_str_t  ngx_http_immutable_types[] = {
        ngx_null_string
};

static ngx_command_t  ngx_http_immutable_commands[] = {

        { ngx_string( "immutable" ),
          NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_FLAG,
          ngx_conf_set_flag_slot,
          NGX_HTTP_LOC_CONF_OFFSET,
          offsetof( ngx_http_immutable_loc_conf_t, enable ),
          NULL },

        { ngx_string("immutable_types"),
          NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_1MORE,
          ngx_http_types_slot,
          NGX_HTTP_LOC_CONF_OFFSET,
          offsetof(ngx_http_immutable_loc_conf_t, types_keys),
          &ngx_http_immutable_types[0] },

        ngx_null_command
};


static ngx_http_module_t  ngx_http_immutable_module_ctx = {
        NULL,                                  /* preconfiguration */
        ngx_http_immutable_init,        /* postconfiguration */

        NULL,                                  /* create main configuration */
        NULL,                                  /* init main configuration */

        NULL,                                  /* create server configuration */
        NULL,                                  /* merge server configuration */

        ngx_http_immutable_create_loc_conf, /* create location config */
        ngx_http_immutable_merge_loc_conf     /* merge location config */
};


ngx_module_t  ngx_http_immutable_module = {
        NGX_MODULE_V1,
        &ngx_http_immutable_module_ctx,       /* module context */
        ngx_http_immutable_commands,          /* module directives */
        NGX_HTTP_MODULE,                       /* module type */
        NULL,                                  /* init master */
        NULL,                                  /* init module */
        NULL,                                  /* init process */
        NULL,                                  /* init thread */
        NULL,                                  /* exit thread */
        NULL,                                  /* exit process */
        NULL,                                  /* exit master */
        NGX_MODULE_V1_PADDING
};


/* next header filter in chain */

static ngx_http_output_header_filter_pt  ngx_http_next_header_filter;

/* header filter handler */

static ngx_int_t
ngx_http_immutable_filter(ngx_http_request_t *r)
{
    ngx_http_immutable_loc_conf_t  *conf;
    ngx_table_elt_t     *e, *cc;
    size_t               len;

    conf = ngx_http_get_module_loc_conf(r, ngx_http_immutable_module);

    if (conf->enable == 0) {
        return ngx_http_next_header_filter(r);
    }

    if (r->headers_out.status != NGX_HTTP_OK
        || r != r->main)
    {
        return ngx_http_next_header_filter(r);
    }

    if (r->http_version < NGX_HTTP_VERSION_11) {
        e = r->headers_out.expires;

        if (e == NULL) {

            e = ngx_list_push(&r->headers_out.headers);
            if (e == NULL) {
                return NGX_ERROR;
            }

            r->headers_out.expires = e;

            e->hash = 1;
            ngx_str_set(&e->key, "Expires");
        }

        len = sizeof("Mon, 28 Sep 1970 06:00:00 GMT");
        e->value.len = len - 1;
        e->value.data = (u_char *) "Thu, 31 Dec 2037 23:55:55 GMT";
    } else {
#if defined(nginx_version) && nginx_version >= 1023000
        cc = r->headers_out.cache_control;

        if (cc == NULL) {

            cc = ngx_list_push(&r->headers_out.headers);
            if (cc == NULL) {
                return NGX_ERROR;
            }

            r->headers_out.cache_control = cc;
            cc->next = NULL;

            cc->hash = 1;
            ngx_str_set(&cc->key, "Cache-Control");

        } else {
            for (cc = cc->next; cc; cc = cc->next) {
                cc->hash = 0;
            }

            cc = r->headers_out.cache_control;
            cc->next = NULL;
        }
#else
        ngx_table_elt_t     **ccp;
        ngx_uint_t           i;
        ccp = r->headers_out.cache_control.elts;

        if (ccp == NULL) {

            if (ngx_array_init(&r->headers_out.cache_control, r->pool,
                               1, sizeof(ngx_table_elt_t *))
                != NGX_OK) {
                return NGX_ERROR;
            }

            cc = ngx_list_push(&r->headers_out.headers);
            if (cc == NULL) {
                return NGX_ERROR;
            }

            cc->hash = 1;
            ngx_str_set(&cc->key, "Cache-Control");

            ccp = ngx_array_push(&r->headers_out.cache_control);
            if (ccp == NULL) {
                return NGX_ERROR;
            }

            *ccp = cc;

        } else {
            for (i = 1; i < r->headers_out.cache_control.nelts; i++) {
                ccp[i]->hash = 0;
            }

            cc = ccp[0];
        }
#endif

        /* 10 years */
        ngx_str_set(&cc->value, "public,max-age=31536000,immutable");
    }

    /* proceed to the next handler in chain */
    return ngx_http_next_header_filter(r);
}


static void *
ngx_http_immutable_create_loc_conf(ngx_conf_t *cf)
{
    ngx_http_immutable_loc_conf_t  *conf;

    conf = ngx_pcalloc(cf->pool, sizeof(ngx_http_immutable_loc_conf_t));
    if (conf == NULL) {
        return NULL;
    }

    conf->enable = NGX_CONF_UNSET;

    return conf;
}


static char *
ngx_http_immutable_merge_loc_conf(ngx_conf_t *cf, void *parent,
                                         void *child)
{
    ngx_http_immutable_loc_conf_t *prev = parent;
    ngx_http_immutable_loc_conf_t *conf = child;

    ngx_conf_merge_value( conf->enable, prev->enable, 0 )

    if (ngx_http_merge_types(cf, &conf->types_keys, &conf->types,
                             &prev->types_keys, &prev->types,
                             ngx_http_immutable_types)
        != NGX_OK)
    {
        return NGX_CONF_ERROR;
    }


    return NGX_CONF_OK;
}


static ngx_int_t
ngx_http_immutable_init(ngx_conf_t *cf)
{
    /* install handler in header filter chain */

    ngx_http_next_header_filter = ngx_http_top_header_filter;
    ngx_http_top_header_filter = ngx_http_immutable_filter;

    return NGX_OK;
}
