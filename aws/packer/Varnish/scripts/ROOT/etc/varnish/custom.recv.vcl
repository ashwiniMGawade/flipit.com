if (client.ip ~ spamlist) {
    set req.backend = spam;
}

if (req.http.User-Agent ~ "Crawlera") {
    error 200 "Please go crawl some else!";
}

if (client.ip ~ block) {
    error 403 "Not allowed";
}

# Do not cache the NginX healthcheck!
if (req.url ~ "^/varnish_health$" ) {
  return (pass);
}

# Do not cache the application-layer healthcheck!
if (req.url ~ "^/health.php$" ) {
  return (pass);
}

# Never cache these pages
if ((req.request == "GET" && (req.url ~ "(.xml|.txt|^/admin|/js/back_end/gtData.js|^/NoCache)")) || req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache" || req.http.Cookie ~ "passCache") {
    set req.http.HTTP_X_PIPE = "1";
    return(pass);
}

if (req.request == "PURGE") {
    ban("req.http.host == " +req.http.host+" && obj.http.content-type ~ "+req.http.content-type);
    error 200 "Ban added";
}

if (req.request == "REFRESH") {
    set req.request = "GET";
    # set req.http.HTTP_X_REFRESH = "1";
    set req.hash_always_miss = true;
}

if(req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache") {
    return (pipe);
}

if (req.url ~ "^(/fi|/jp|/tr|/uk|/za|/kr|/ar|/ru|/hk|/sk|/cl|/ie|/mx|/cn)(/|$)" ){
    error 404 "This locale doesn't yet exist. Stay tuned!";
}

# Migration to cuponation
if (req.url ~ "^(/no)(/|$)" ){
    set req.http.HTTP_X_PIPE = "1";
    return(pass);
}
if (req.url ~ "^(/br)(/|$)" ){
    set req.http.HTTP_X_PIPE = "1";
    return(pass);
}
if (req.url ~ "^(/au)(/|$)" ){
    set req.http.HTTP_X_PIPE = "1";
    return(pass);
}

set req.http.HTTP_X_VARNISH = "1";
