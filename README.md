# README #

### Summary ###

Dehydrated BIGIP is an hook/extension for "dehydrated" which is a LetsEncrypt client written entirely in Bash shell.

"dehydrated-bigip" is called by "dehydrated" in order to perform a number of tasks:

* add LetsEncrypt verification tokens to a data group used by an iRule to respond to LetsEncrypt verification requests
* Upload certs/keys to BIGIP's and create cert/key objects from them
* Create client SSL profile/s from cert/key objects
* Add/replace client SSL profile/s on specific virtual servers

All interaction with the BIGIP system occurs via REST API.

Included as part of "dehydrated-bigip" is the "F5CommonRESTAPIs.sh" file; forked from the original within here: https://github.com/john3exonets/f5-example-bash-icontrol-rest-apis

### How do I get set up? ###

* Summary of set up

0. Add LetsEncrypt verification iRule to F5 BIGIP; modify data group name if desired
1. Get dehydrated installed and configured/working
2. Get dehydrated-bigip installed and configured
3. Get dehydrated to use dehydrated-bigip as a hook; either via CLI argument or HOOK config variable

* Dependencies

Dehydrated is available here: https://github.com/lukas2511/dehydrated

Clone or download the dehydrated script and install to a folder within your $PATH environment variable.

Setup dehydrated as per original instructions.

* Configuration

Example modifications to dehydrated.conf

```
#!shell

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

Edit the following variables within dehydrated-bigip

```
#!shell

export BIGIP_Addrs="192.168.1.245"
export BIGIP_User="admin"
export BIGIP_Passwd="admin"
export BIGIP_Partition="Common"
export GRPNAME="certbot_validator"
export CLIENT_SSL_DEFAULT="/Common/clientssl"
export CURL="/usr/bin/curl"
export LOGFILE='./dehydrated-bigip.log'
```

Add host/domain names to %{PATH}%/dehydrated.conf

Each line will be treated as a separate certificate; the first name is the primary certificate name, additional names will be included as SAN's.

```
#!shell

$ cat ~/etc/dehydrated/domains.txt
localhost4.localdomain4
localhost6.localdomain6
$
```

### Example Usage ###

1. Updating certificates on F5 BIGIP

```
#!shell

%{TBC}%
```

