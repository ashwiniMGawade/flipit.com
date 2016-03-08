include "custom.backend.vcl";
include "custom.acl.vcl";

C{
#include <netinet/in.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
}C

# Handle the HTTP request received by the client
sub vcl_recv {

   C{
        // This is a hack from Igor Gariev (gariev hotmail com):
        // Copy IP address from "X-Forwarded-For" header
        // into Varnish's client_ip structure.
        // This works with Varnish 3.0.1; test with other versions
        //
        // Trusted "X-Forwarded-For" header is a must!
        // No commas are allowed. If your load balancer something other
        // than a single IP, then use a regsub() to fix it.
        //
        struct sockaddr_storage *client_ip_ss = VRT_r_client_ip(sp);
        struct sockaddr_in *client_ip_si = (struct sockaddr_in *) client_ip_ss;
        struct in_addr *client_ip_ia = &(client_ip_si->sin_addr);
        char *xff_ip = VRT_GetHdr(sp, HDR_REQ, "\020X-Forwarded-For:");

        if (xff_ip != NULL) {
        // Copy the ip address into the struct's sin_addr.
        inet_pton(AF_INET, xff_ip, client_ip_ia);
        }
    }C

    # shortcut for DFind requests
    if (req.url ~ "^/w00tw00t") {
        error 404 "Not Found";
    }

    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Normalize the header, remove the port (in case you're testing this on various TCP ports)
    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    # Only deal with "normal" types
    if (req.request != "GET" &&
            req.request != "HEAD" &&
            req.request != "PUT" &&
            req.request != "POST" &&
            req.request != "TRACE" &&
            req.request != "OPTIONS" &&
            req.request != "PATCH" &&
            req.request != "REFRESH" &&
            req.request != "PURGE" &&
            req.request != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.request != "GET" && req.request != "HEAD" && req.request != "REFRESH" && req.request != "PURGE" ) {
       return (pass);
    }

    # Configure grace period, in case the backend goes down. This allows otherwise "outdated"
    # cache entries to still be served to the user, because the backend is unavailable to refresh them.
    # This may not be desireable for you, but showing a Varnish Guru Meditation error probably isn't either.
    if (req.backend.healthy) {
        set req.grace = 30s;
    } else {
        unset req.http.Cookie;
        set req.grace = 6h;
    }

    # Never cache these pages
    if (req.request == "GET" && (req.url ~ "(/out/)")) {
        set req.http.HTTP_X_PIPE = "1";
        return(pass);
    }

    # Some generic URL manipulation, useful for all templates that follow
    # First remove the Google Analytics added parameters, useless for our backend
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip a trailing ? if it exists
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Some generic cookie manipulation, useful for all templates that follow
    # Remove the "has_js" cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Remove any Google Analytics based cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

    # Remove the Quant Capital cookies (added by some plugin, all __qca)
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

    # Remove the AddThis cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuvc=[^;]+(; )?", "");

    # Remove a ";" prefix in the cookie if present
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

    # Are there cookies left with only spaces or that are empty?
    if (req.http.cookie ~ "^\s*$") {
        unset req.http.cookie;
    }

    # Normalize Accept-Encoding header
    # straight from the manual: https://www.varnish-cache.org/docs/3.0/tutorial/vary.html
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            # No point in compressing these
            remove req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            # unkown algorithm
            remove req.http.Accept-Encoding;
        }
    }

    # Large static files should be piped, so they are delivered directly to the end-user without
    # waiting for Varnish to fully read the file first.
    # TODO: once the Varnish Streaming branch merges with the master branch, use streaming here to avoid locking.
    if (req.url ~ "^[^?]*\.(mp[34]|rar|tar|tgz|gz|wav|zip)(\?.*)?$") {
        unset req.http.Cookie;
        return (pipe);
    }

    # Remove all cookies for static files
    # A valid discussion could be held on this line: do you really need to cache static files that don't cause load? Only if you have memory left.
    # Sure, there's disk I/O, but chances are your OS will already have these files in their buffers (thus memory).
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/
    if (req.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|pdf|png|rtf|swf|txt|woff|xml)(\?.*)?$") {
        unset req.http.Cookie;
        return (lookup);
    }

    if (req.http.Authorization) {
        # Not cacheable by default
        return (pass);
    }

    # Include custom vcl_recv logic
    include "custom.recv.vcl";

    return (lookup);
}

sub vcl_pipe {
    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.

    #set bereq.http.Connection = "Close";
    return (pipe);
}

sub vcl_pass {
    return (pass);
}

# The data on which the hashing will take place
sub vcl_hash {
    hash_data (req.url);
    hash_data (req.http.host);

    if( req.http.Cookie ~ "kc_unique_user_id" ) {
        set req.http.X-Varnish-Hashed-On =
            regsub( req.http.Cookie, "^.*?kc_unique_user_id=([^;]*);*.*$", "\1" );
    }

    if( req.url ~ "/login/usermenu" && req.http.X-Varnish-Hashed-On ) {
        hash_data("logged in");
    }

    if( req.url ~ "/signup/signupwidgetcodes" && req.http.X-Varnish-Hashed-On ) {
        hash_data("logged in");
    }

    if( req.url ~ "/signup/signupmembersonlytitle" && req.http.X-Varnish-Hashed-On ) {
        hash_data("logged in");
    }

    if( req.url ~ "/store/followbutton" && req.http.X-Varnish-Hashed-On ) {
        hash_data (req.http.X-Varnish-Hashed-On);
    }

    if( req.http.Cookie ~ "registered_user" ) {
        set req.http.X-Varnish-Registered-Hashed-On = "1";
    }

    if( req.url ~ "signupwidgetlarge" && req.http.X-Varnish-Registered-Hashed-On ) {
        hash_data("registered");
    }

    if( req.url ~ "signupwidget" && req.http.X-Varnish-Registered-Hashed-On ) {
        hash_data("registered");
    }

    if( req.url ~ "signupwidgetfooter" && req.http.X-Varnish-Registered-Hashed-On ) {
        hash_data("registered");
    }

    return (hash);
}

sub vcl_hit {
    # Allow purges
    if (req.request == "PURGE") {
        purge;
        error 200 "purged";
    }

    return (deliver);
}

sub vcl_miss {
    # Allow purges
    if (req.request == "PURGE") {
        purge;
        error 200 "purged";
    }

    return (fetch);
}

# Handle the HTTP request coming from our backend
sub vcl_fetch {
    # Include custom vcl_fetch logic
    include "custom.fetch.vcl";

    if (beresp.http.esi-enabled == "1") {
        set beresp.do_esi = true; /* Do ESI processing */
        unset beresp.http.esi-enabled;
    }

    # https://www.varnish-cache.org/docs/3.0/tutorial/compression.html
    # gzip content that can be compressed
    # Do wildcard matches, since additional info (like charsets) can be added in the Content-Type header
    if (beresp.http.content-type ~ "text/plain"
          || beresp.http.content-type ~ "text/xml"
          || beresp.http.content-type ~ "text/css"
          || beresp.http.content-type ~ "text/html"
          || beresp.http.content-type ~ "application/(x-)?javascript"
          || beresp.http.content-type ~ "application/(x-)?font-ttf"
          || beresp.http.content-type ~ "application/(x-)?font-opentype"
          || beresp.http.content-type ~ "application/font-woff"
          || beresp.http.content-type ~ "application/vnd\.ms-fontobject"
          || beresp.http.content-type ~ "image/svg\+xml"
       ) {
        set beresp.do_gzip = true;
    }

    # If the request to the backend returns a code is 5xx, restart the loop
    # If the number of restarts reaches the value of the parameter max_restarts,
    # the request will be error'ed.  max_restarts defaults to 4.  This prevents
    # an eternal loop in the event that, e.g., the object does not exist at all.
    if (beresp.status >= 500 && beresp.status <= 599){
        return(restart);
    }

    # Enable cache for all static files
    # The same argument as the static caches from above: monitor your cache size, if you get data nuked out of it, consider giving up the static file cache.
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/
    if (req.url ~ "^[^?]*\.(bmp|bz2|doc|eot|flv|gif|gz|ico|jpeg|jpg|less|mp[34]|pdf|png|rar|rtf|swf|tar|tgz|txt|wav|woff|xml|zip)(\?.*)?$") {
        set beresp.ttl = 365d;
        set beresp.http.Cache-Control = "max-age = 31536000";
        unset beresp.http.set-cookie;
    }

    if (beresp.status >= 500 || beresp.status == 301 || beresp.status == 302 || beresp.http.X-Nocache  == "no-cache" || (req.url ~ "store/followbutton" && req.http.X-Varnish-Hashed-On )) {
        set beresp.ttl = 0s;
        set beresp.http.Cache-Control = "max-age = 0";
    } elseif (req.request != "POST" && beresp.http.Set-Cookie !~ "delete") {
        set beresp.ttl = 24 h;
        set beresp.http.Cache-Control = "max-age = 3600";
        unset beresp.http.Pragma;
        unset beresp.http.Expires;
        unset beresp.http.Set-Cookie;
    }

    # Keep all objects for 6h longer in the cache than their TTL specifies.
    # So even if HTTP objects are expired (they've passed their TTL), we can still use them in case all backends go down.
    # Remember: old content to show is better than no content at all (or an error page).
    set beresp.grace = 6h;

    return (deliver);
}

# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "cached";
    } else {
        set resp.http.x-Cache = "uncached";
    }

    # Remove some headers: PHP version
    unset resp.http.X-Powered-By;

    # Remove some headers: Apache version & OS
    unset resp.http.Server;
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Link;

    return (deliver);
}

sub vcl_error {
    if (obj.status >= 500 && obj.status <= 599 && req.restarts < 4) {
        # 4 retry for 5xx error
        return(restart);
    } elseif (obj.status >= 400 && obj.status <= 499 ) {
        # use 404 error page for 4xx error
        include "conf.d/error-404.vcl";
    } elseif (obj.status == 720) {
        # We use this special error status 720 to force redirects with 301 (permanent) redirects
        # To use this, call the following from anywhere in vcl_recv: error 720 "http://host/new.html"
        set obj.status = 301;
        set obj.http.Location = obj.response;
        return (deliver);
    } elseif (obj.status == 721) {
        # And we use error status 721 to force redirects with a 302 (temporary) redirect
        # To use this, call the following from anywhere in vcl_recv: error 720 "http://host/new.html"
        set obj.status = 302;
        set obj.http.Location = obj.response;
        return (deliver);
    } else {
        # for other errors (not 5xx, not 4xx and not 2xx)
        include "conf.d/error.vcl";
    }

    return (deliver);
}

sub vcl_init {
    return (ok);
}

sub vcl_fini {
    return (ok);
}
