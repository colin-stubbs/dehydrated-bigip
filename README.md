# README #

### Summary ###

"dehydrated-bigip" provides hooks/extensions to "dehydrated", which is a LetsEncrypt client written entirely in Bash shell, in order to automate ACME based challenge validation via and certificate/key deployment to F5 BIG-IP appliances.

HTTP-01 and DNS-01 based validation processes can both be used; but are supported using different hook scripts.

"dehydrated-bigip-http-01" implements all HTTP-01 based validation functions on a BIGIP system. You would typically use this for traffic certificates, e.g. certificates are used as part of Client/Server SSL profiles on virtual servers, it cannot be used for BIG-IP management interface certificates.

It is called by "dehydrated" in order to perform a number of tasks:

* Add LetsEncrypt verification tokens to a data group used by an iRule to respond to LetsEncrypt verification requests
* Upload certs/keys to BIGIP's and create cert/key objects from them
* Create client SSL profile/s from cert/key objects
* Add/replace client SSL profile/s on specific virtual servers

"dehydrated-bigip-deploy-traffic-certificate" implements certificate deployment to BIG-IP for traffic management certificates. e.g. certificates are used as part of Client/Server SSL profiles on virtual servers.

You would typically use this hook after successful DNS-01 based validation occurs; in order to deploy the certificates obtained by dehydrated and the prior DNS-01 hook.

DNS-01 challenge and validation needs to be implemented by another hook first however.

It can called by "dehydrated" and performs the following tasks:

* Upload certs/keys to BIGIP's and create cert/key objects from them
* Create client SSL profile/s from cert/key objects
* Add/replace client SSL profile/s on specific virtual servers

"dehydrated-bigip-deploy-management-certificate" implements certificate deployment to BIG-IP only. You would typically use this after successful DNS-01 based validation occurs; in order to deploy the certificates obtained by dehydrated and the prior DNS-01 hook.

DNS-01 challenge and validation needs to be implemented by another hook first however.

It can called by "dehydrated" and performs the following tasks:

* Upload certs/keys to BIGIP's and create cert/key objects from them
* Create client SSL profile/s from cert/key objects
* Add/replace client SSL profile/s on specific virtual servers

All interaction with the BIGIP system occurs via REST API.

Included as part of "dehydrated-bigip" is the "F5CommonRESTAPIs.sh" file; forked from the original here: https://github.com/john3exonets/f5-example-bash-icontrol-rest-apis

### How do I get set up? ###

* Summary of set up

For HTTP-01 based validation,

0. Add LetsEncrypt verification iRule to F5 BIGIP; modify data group name if desired
1. Get dehydrated installed and configured/working
2. Get dehydrated-bigip installed and configured
3. Get dehydrated to use dehydrated-bigip as a hook; either via CLI argument or HOOK config variable

For DNS-01 based validation,

0. Get dehydrated installed and configured/working with a hook to perform DNS-01 based validation in order to obtain certificates
2. Get dehydrated-bigip installed and configured
3. Get dehydrated to use dehydrated-bigip as a hook; either via CLI argument or HOOK config variable

* Dependencies

** dehydrated

Dehydrated is available here: https://github.com/lukas2511/dehydrated

Clone or download the dehydrated script and install to a folder within your $PATH environment variable.

Setup dehydrated as per original instructions.

** DNS-01 hook/validation

Review the available DNS-01 validation methods here: https://github.com/lukas2511/dehydrated/wiki/Examples-for-DNS-01-hooks

lexicon is my recommended tool, give the wide array of API's/etc that it supports.

https://github.com/AnalogJ/lexicon/

* Configuration

Example modifications to dehydrated.conf

```
$ cat ~/etc/dehydrated/dehydrated.conf  | grep -v -e ^# -e ^$
CHALLENGETYPE="http-01"
BASEDIR="/Users/user/etc/dehydrated"
CERTDIR="${BASEDIR}/certs"
ACCOUNTDIR="${BASEDIR}/accounts"
WELLKNOWN="${BASEDIR}/wellknown"
KEYSIZE="4096"
HOOK="/Users/user/bin/dehydrated-bigip"
PRIVATE_KEY_RENEW="yes"
KEY_ALGO=rsa
CONTACT_EMAIL=muppet@some.domain.tld
$
```

Edit the following variables within dehydrated-bigip,

```
BIGIP_DEVICE_LIST="192.168.1.245 192.168.1.246"
BIGIP_USERNAME="admin"
BIGIP_PASSWORD="admin"
BIGIP_PARTITION="Common"
BIGIP_DATA_GROUP_NAME="certbot_validator"
BIGIP_CLIENT_SSL_PARENT="/Common/clientssl"
TIMESTAMP_NAME="1"
OCSP_STAPLING_PROFILE="/Common/ocsp"
CURL="/usr/bin/curl"
LOGFILE='./dehydrated-bigip.log'
```

At present, within dehydrated-bigip direct from the git repo, the values are represented with Jinja variable bracketing and so immediately included as part of a Salt Stack state or similar.

e.g.

```
BIGIP_DEVICE_LIST_List="{{ bigip_device_list }}"
BIGIP_USERNAME="{{ bigip_username }}"
BIGIP_PASSWORD='{{ bigip_password }}'
BIGIP_PARTITION="{{ bigip_partition }}"
BIGIP_DATA_GROUP_NAME="{{ bigip_data_group }}"
BIGIP_CLIENT_SSL_PARENT="{{ bigip_clientssl_parent }}"
TIMESTAMP_NAME="{{ bigip_timestamp_name }}"
OCSP_STAPLING_PROFILE="{{ bigip_ocsp_profile }}"
```

Add host/domain names to %{PATH}%/domains.txt

Each line will be treated as a separate certificate; the first name is the primary certificate name, additional names will be included as SAN's.

```
$ cat ~/etc/dehydrated/domains.txt
localhost4.localdomain4
localhost6.localdomain6
$
```

### Example Usage ###

1. Updating certificates on F5 BIGIP

```
%{TBC}%
```

### TODO ###

0. Cleanup the code. It's a bit crap.
1. Improve error handling and logging
2. Ensure proper BIGIP partition support is handled in the same way throughput script
3. Improve handling of > 1 BIGIP situations (seems OK with 2 but it's not great)
4. Encrypt private keys on disk and prior to sending to BIGIP; re-encrypt with random password before sending to BIGIP; create/update client SSL profile with random password when changed
5. Use secure/encrypted storage in some way, e.g. network HSM's, Hashicorp's Vault, Veracrypt etc
