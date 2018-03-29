rule IRULE-LetsEncrypt-Validation-1 {
when RULE_INIT {
    set static::certbot_validator_class {letsencrypt_http-01}
}
when HTTP_REQUEST {
    if { [string tolower [HTTP::uri]] starts_with {/.well-known/acme-challenge/}
      and [class match [HTTP::uri] ends_with ${static::certbot_validator_class}] != {} } {
        set response_content [class lookup [substr [HTTP::uri] 28] ${static::certbot_validator_class}]
        if { ${response_content} != {} } {
            HTTP::respond 200 -version auto content [class lookup [substr [HTTP::uri] 28] ${static::certbot_validator_class}]
        } else {
            HTTP::respond 503 -version auto content {<html><body><h1>503 - Errorz!</h1><p>soz content not here!</body></html>}
        }
        unset response_content
    }
}
}
