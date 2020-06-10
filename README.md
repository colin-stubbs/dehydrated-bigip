# README #

# THIS IS NOW A DEFUNCT PROJECT AND WILL NOT BE UPDATED. #

For the next iteration that's based on Ansible (instead of a nightmare of bash) to interact with a BIG-IP system, refer to: https://github.com/EquateTechnologies/dehydrated-bigip-ansible

## Summary ##

"dehydrated-bigip" is a hook for "[dehydrated](https://github.com/lukas2511/dehydrated)", which is a Let's Encrypt client written entirely in Bash shell.

"dehydrated-bigip" uses the BIG-IP iControl REST API for all interaction with BIG-IP systems; no SSH or iControl SOAP API.

This provides automation for ACME based challenge validation via and certificate/key deployment to F5 BIG-IP appliances.

HTTP-01 and DNS-01 based validation processes can both be used; but are supported using different hook scripts.

Recently tested with BIG-IP versions:
* VE, 13.1.0.3.0.0.5
* VE, 13.0.0.2.0.1671

## HTTP-01 for BIG-IP Traffic Certificates/Keys ##

"dehydrated-bigip-http-01" implements all HTTP-01 based validation functions on a BIG-IP system. You would typically use this for traffic certificates, e.g. certificates are used as part of Client/Server SSL profiles on virtual servers, it cannot be used for BIG-IP management interface certificates.

It is called by "dehydrated" in order to perform the following:
* Add Let's Encrypt verification tokens to a data group, which is used by an iRule, associated with all necessary virtual servers, to respond to Let's Encrypt HTTP-01 validation requests

"dehydrated-bigip-http-01" implements the following hook calls using functions:
* deploy_challenge
* clean_challenge

"dehydrated-bigip-http-01" then uses the traffic certificate deployment hook below, "dehydrated-bigip-deploy-traffic-certificate", to deploy certificates and keys to each BIG-IP in the deployment list.

NOTE: No, this method can't be used for BIG-IP management certificates, nor should it.

## DNS-01 for BIG-IP Traffic Certificates/Keys ##

"dehydrated-bigip-dns-01" is an example of a composite hook that leverages something else to complete DNS-01 based validation and certificate/key deployment to BIG-IP's as traffic certs, e.g. those used on virtual servers.

The script does not directly implement an hook calls, rather it passes them to the script that handles DNS modifications (e.g. lexicon), and for each BIG-IP in the deployment list

It is by default configured to use "/etc/dehydrated/hooks/dehydrated-lexicon", which is an example of how to use lexicon. lexicon supports a large number of DNS service providers by way of API's, https://github.com/AnalogJ/lexicon

It then uses the traffic certificate deployment hook below, "dehydrated-bigip-deploy-traffic-certificate", to deploy certificates and keys to each BIG-IP in the deployment list.

## DNS-01 for BIG-IP Management Interface Certificates/Keys ##

"dehydrated-bigip-dns-01-management-certificate" is an example of a composite hook that leverages something else to complete DNS-01 based validation and certificate/key deployment to a single BIG-IP's management web interface.

The script does not directly implement an hook calls, rather it passes them to the script that handles DNS modifications (e.g. lexicon), and for each BIG-IP in the deployment list

It is by default configured to use "/etc/dehydrated/hooks/dehydrated-lexicon", which is an example of how to use lexicon. lexicon supports a large number of DNS service providers by way of API's, https://github.com/AnalogJ/lexicon

It then uses the traffic certificate deployment hook below, "dehydrated-bigip-deploy-management-certificate", to deploy the  certificate and key to the same BIG-IP as named by the certificate.

NOTE: The name for the certificate must match an internal/reachable management interface for the BIG-IP; otherwise deployment will fail.

## BIG-IP Traffic Certificate/Key Deployment ##

"dehydrated-bigip-deploy-traffic-certificate" implements the following hook calls using functions:
* deploy_cert

It performs the following tasks using the BIG-IP iControl REST API:

* Upload certs/keys/chains to BIG-IP's and create cert/key objects from them
* Create/update client SSL profile/s based on cert/key objects and the named parent profile

## BIG-IP Management Certificate/Key Deployment ##

"dehydrated-bigip-deploy-management-certificate" implements the following hook calls using functions:
* deploy_cert

It performs the following tasks using the BIG-IP iControl REST API:

* Upload full chain and key to BIG-IP (/etc/httpd/conf/ssl.key/${DOMAIN}.crt, /etc/httpd/conf/ssl.key/${DOMAIN}.key)
* Modify "sys httpd" configuration object to leverage new full chain and key
* Restart the "httpd" service on the BIG-IP

## BIG-IP Traffic Certificate/Key Re-deployment ##

"dehydrated-bigip-redeploy-traffic-certificate" implements the following hook calls using functions:
* unchanged_cert

This is simply "proxied" to "dehydrated-bigip-deploy-traffic-certificate" using the hook call "deploy_cert"

This is useful to trigger re-deployment of certs/keys to BIG-IP's that may not have them already.

## BIG-IP Management Certificate/Key Re-deployment ##

"dehydrated-bigip-redeploy-management-certificate" implements the following hook calls using functions:
* unchanged_cert

This is simply "proxied" to "dehydrated-bigip-deploy-management-certificate" using the hook call "deploy_cert"

This is useful to trigger re-deployment of certs/keys to BIG-IP's that may not have them already.

## How do I get it set up and doing something useful ? ##

### Summary ###

#### For HTTP-01 based validation ####

0. Add Let's Encrypt verification iRule to F5 BIG-IP; modify data group name if desired
1. Get dehydrated installed and configured/working, e.g. create /etc/dehydrated/conf.d/local.sh with config variables
2. Get dehydrated-bigip installed and configured
3. Get dehydrated to use dehydrated-bigip-http-01 as a hook; either via CLI argument or HOOK config variable

Example local.sh variables file,

````
# /etc/dehydrated/conf.d/local.sh

unset proxy
unset http_proxy
unset https_proxy
unset ftp_proxy
unset no_proxy

BIGIP_DEVICE_LIST='bigip1.localdomain bigip2.localdomain'
BIGIP_USERNAME='admin'
BIGIP_PASSWORD='admin'
BIGIP_PARTITION='Common'
BIGIP_DATA_GROUP_NAME='letsencrypt_http-01'
BIGIP_CLIENT_SSL_MANAGE='1'
BIGIP_CLIENT_SSL_PARENT='/Common/clientssl'
TIMESTAMP_NAME='0'
OCSP_STAPLE='1'
OCSP_STAPLING_PROFILE='/Common/OCSP-STAPLE-LetsEncrypt-X3'
BIGIP_SAVE_CONFIG='1'

# EOF
````

#### For DNS-01 based validation ####

0. Get dehydrated installed and configured/working with a hook to perform DNS-01 based validation in order to obtain certificates
1. Get dehydrated-lexicon (or nsupdate etc) installed and configured, e.g. create /etc/dehydrated/conf.d/local.sh with config variables
2. Get dehydrated-bigip installed and configured, e.g. create /etc/dehydrated/conf.d/local.sh with config variables
3. Get dehydrated to use dehydrated-bigip-dns-01 as a hook; either via CLI argument or HOOK config variable

Example local.sh variables file,

````
# /etc/dehydrated/conf.d/local.sh

unset proxy
unset http_proxy
unset https_proxy
unset ftp_proxy
unset no_proxy

BIGIP_DEVICE_LIST='bigip1.localdomain bigip2.localdomain'
BIGIP_USERNAME='admin'
BIGIP_PASSWORD='admin'
BIGIP_PARTITION='Common'
BIGIP_CLIENT_SSL_MANAGE='1'
BIGIP_CLIENT_SSL_PARENT='/Common/clientssl'
TIMESTAMP_NAME='0'
OCSP_STAPLE='1'
OCSP_STAPLING_PROFILE='/Common/OCSP-STAPLE-LetsEncrypt-X3'
BIGIP_SAVE_CONFIG='1'

LEXICON_PROVIDER='dnsmadeeasy'
LEXICON_ARGS='--auth-username %{REMOVED}% --auth-token %{REMOVED}%'

# EOF
````

## How do I ensure it's all automated and I never have to think about this again? ##

Errr... good luck with that pipe dream. Everything needs maintenance.

But start by creating a cron task to run dehydrated periodically. You'll need several different commands depending on which groups of certs you want to get and deploy to various BIG-IP's.

Example:

```
# /etc/cron.d/dehydrated
#
# Automates certificate renewal and deployment using Let's Encrypt via dehydrated
#
# traffic certificates which are currently deployed to all BIG-IP's.
# the config file in thise case points to the correct hook or hook chain to use
10 1 * * 3 root test -s /etc/dehydrated/config && test -s /etc/dehydrated/domains.txt && /usr/bin/dehydrated --cron

# management certificates which are currently explicitly named and deployed to a single BIG-IP at a time

# bigip1.domain.tld cert
20 1 * * 3 root test -s /etc/dehydrated/hooks/dehydrated-bigip-dns-01-management-certificate && dehydrated --cron --domain bigip1.domain.tld --hook /etc/dehydrated/hooks/dehydrated-bigip-dns-01-management-certificate

# bigip2.domain.tld cert
25 1 * * 3 root test -s /etc/dehydrated/hooks/dehydrated-bigip-dns-01-management-certificate && dehydrated --cron --domain bigip2.domain.tld --hook /etc/dehydrated/hooks/dehydrated-bigip-dns-01-management-certificate

# EOF
```

## Dependencies ##

### dehydrated ###

If using Fedora you should be able to install the 'dehydrated' package immediately.

If using Enterprise Linux (RedHat/CentOS) variants you should be able to install the 'dehydrated' package after adding the EPEL repository.

If install from source got straight to GitHub; dehydrated is available here: https://github.com/lukas2511/dehydrated

Clone or download the dehydrated script and install to a folder within your $PATH environment variable.

Setup dehydrated as per original instructions.

### DNS Modification Methods ###

Review the available DNS-01 hook options here: https://github.com/lukas2511/dehydrated/wiki/Examples-for-DNS-01-hooks

lexicon is my recommended tool, give the wide array of API's/etc that it supports.

https://github.com/AnalogJ/lexicon/

You'll most likely need to install using pip; I'm yet to find an RPM in any repository that actually includes the 'lexicon' command in a bin directory. pip should install /usr/bin/lexicon for you.

Included in this repository are the following scripts which provide examples for how to use lexicon as well as nsupdate for DNS modifications:
* dehdyrated-lexicon
* dehydrated-nsupdate

If using these examples you should configure lexicon using variables via /etc/dehydrated/conf.d/local.sh or another .sh file.

Example for lexicon,


```
LEXICON_PROVIDER='dnsmadeeasy'
LEXICON_ARGS='--auth-username %{REMOVED}% --auth-token %{REMOVED}%'
```

Example for nsupdate,

```
NSUPDATE_ARGS='-k /etc/dehydrated/hooks/nsupdate-dns-01.key'
NSUPDATE_SERVER_LIST='203.0.113.0'
```

### dehydrated Configuration ###

WARNING: dehydrated-bigip does not yet support configuring OCSP stapling correctly... will be added soon. In the mean time DO NOT set OCSP_MUST_STAPLE='yes'

```
[user@box ~]# cat /etc/dehydrated/config_dns-01 | grep -v -e ^# -e ^$
CA="https://acme-v01.api.letsencrypt.org/directory"
CA_TERMS="https://acme-v01.api.letsencrypt.org/terms"
CHALLENGETYPE="dns-01"
CONFIG_D="${BASEDIR}/conf.d"
DOMAINS_TXT="${BASEDIR}/domains.txt"
WELLKNOWN="/var/www/dehydrated"
KEYSIZE="2048"
HOOK="${BASEDIR}/hooks/dehydrated-bigip-dns-01"
RENEW_DAYS="30"
PRIVATE_KEY_RENEW="yes"
CONTACT_EMAIL=security@domain.tld
LOCKFILE="/run/dehydrated/lock"
OCSP_MUST_STAPLE="no"
AUTO_CLEANUP="yes"
[user@box ~]#
```

### Example Usage ###

1. traffic certificates via HTTP-01 deployed to a single BIG-IP

```
%{TBC}%
```

2. traffic certificates via DNS-01 deployed to a single BIG-IP

```
%{TBC}%
```

3. management certificates via DNS-01 for a single BIG-IP

```
%{TBC}%
```

### TODO ###

0. Clean up the code. It's a bit crap.
1. Improve error handling and logging
2. Ensure proper BIG-IP partition support is handled in the same way throughput script
3. Improve handling of > 1 BIG-IP situations (seems OK with 2 but it's not great), e.g. only deploy to active units not standby
4. Encrypt private keys on disk and prior to sending to BIG-IP; re-encrypt with random password before sending to BIG-IP; create/update client SSL profile with random password when changed
5. Use secure/encrypted storage in some way, e.g. network HSM's, Hashicorp's Vault, Veracrypt etc
6. OCSP stapling for traffic certs and management certs, e.g. based on OCSP_STAPLE and OCSP_STAPLING_PROFILE config
7. Cert/key object timestamping, e.g. based on TIMESTAMP_NAME
8. Optional management of client SSL profiles, BIGIP_CLIENT_SSL_MANAGE
9. Support for creation/modification of server SSL profiles
10. BIG-IP config save after changes, e.g. iControl REST API equivalent of 'tmsh save sys config'
