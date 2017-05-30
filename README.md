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
  export BIGIP_Addrs="192.168.1.245 192.168.1.246"
  export BIGIP_User="admin"
  export BIGIP_Passwd="admin"
  export BIGIP_Partition="Common"
  export BIGIP_Data_Group_Name="certbot_validator"
  export BIGIP_Client_SSL_Parent="/Common/clientssl"
  export TIMESTAMP_NAME="1"
  export OCSP_STAPLING_PROFILE="/Common/ocsp"
  export CURL="/usr/bin/curl"
  export LOGFILE='./dehydrated-bigip.log'
```

At present, within dehydrated-bigip direct from the git repo, the values are represented with Jinja variable bracketing and so immediately included as part of a Salt Stack state or similar.

e.g.

```
  export BIGIP_Addrs_List="{{ bigip_device_list }}"
  export BIGIP_User="{{ bigip_username }}"
  export BIGIP_Passwd='{{ bigip_password }}'
  export BIGIP_Partition="{{ bigip_partition }}"
  export BIGIP_Data_Group_Name="{{ bigip_data_group }}"
  export BIGIP_Client_SSL_Parent="{{ bigip_clientssl_parent }}"
  export TIMESTAMP_NAME="{{ bigip_timestamp_name }}"
  export OCSP_STAPLING_PROFILE="{{ bigip_ocsp_profile }}"
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
4. Encrypt private keys on disk and prior to sending to BIGIP; re-encrypt with random password before sening to BIGIP; create/update client SSL profile with random password when changed
5. Use secure/encrypted storage in some way, e.g. network HSM's, Hashicorp's Vault, Veracrypt etc
