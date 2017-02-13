#!/bin/bash
#
#  Updated with minor bug fix to support dehydrated-bigip
#  Colin Stubbs (cstubbs _at_ gmail #dot# com)
#  December 2016
#
#  Sample F5 BIGIP Reset Configuration script
#  John D. Allen
#  April, 2016
#
#-----------------------------------------------------------------------------------
# Software is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 2016 F5 Networks,
# Inc. All Rights Reserved.
#
# Author: John D. Allen, Solution Architect, F5 Networks
# Email: john.allen@f5.com
#-----------------------------------------------------------------------------------
# This file contains a number of common iControl REST API functions that are used
# by the other bash scripts.
#

#-------------------------------------------------------
# Function: log()
#-------------------------------------------------------
DATE='date +%m/%d/%Y:%H:%M:%S'
log() {
  echo `$DATE`" $*" >> $LOGFILE
}

#-------------------------------------------------------
# Function: restCall()
#-------------------------------------------------------
restCall() {
  # $1 => Type (GET, PUT, POST, DELETE, PATCH, etc.)
  # $2 => URL past 'mgmt'  Example: "/tm/security/firewall/policy/~Common~TestPolicy1" for
  #       https://10.147.29.215/mgmt/tm/security/firewall/policy/~Common~TestPolicy1
  # $3 => JSON payload, if any.

  CONTTYPE="--header Content-Type: application/json"
  AUTH="-u $BIGIP_User:$BIGIP_Passwd"
  TIME="--connect-timeout $TIMEOUT"
  MAXTIME="-m $MAXTIMEOUT"
  URL="https://$BIGIP_Addrs/mgmt$2"
  if [[ $1 == POST || $1 == PATCH || $1 == PUT ]]; then
    log "restCall():${CURL} -sk ${TIME} ${MAXTIME} ${CONTTYPE} ${AUTH} ${URL} -X $1 -d \"$3\""
    ${CURL} -sk ${TIME} ${MAXTIME} ${CONTTYPE} ${AUTH} ${URL} -X $1 -d "$3"
  else
    log "restCall():${CURL} -sk ${TIME} ${MAXTIME} ${CONTTYPE} ${AUTH} ${URL} -X $1 "
    ${CURL} -sk ${TIME} ${MAXTIME} ${CONTTYPE} ${AUTH} ${URL} -X $1
  fi
}

#-------------------------------------------------------
# Function: isAvailable()
#   Tests to see if BIGIP is ready to accept API calls.
#-------------------------------------------------------
isAvailable() {
  OUT=$(restCall "GET" "/tm/ltm/available")
  log "isAvailable():`echo $OUT`"
  if [[ $(echo $OUT) == "{}" ]]; then
    return 0
  else
    return 1
  fi
}

#-------------------------------------------------------
# Function: whenAvailable()
#  Waits for BIGIP to become available, within the
#  MAXTIMEOUT value.
#-------------------------------------------------------
whenAvailable() {
  # $SECONDS is a built-in Bash var for # of seconds Bash has been running.
  STARTTIME=$SECONDS
  while true; do
    sleep 1
    if (isAvailable); then
      return 0
    fi
    duration=$SECONDS
    if [[ $(($duration - $STARTTIME)) -gt $MAXTIMEOUT ]]; then
      return 1
    fi
  done
}

#-------------------------------------------------------
# Function: waitForActiveStatus()
#  Waits for the BIGIP to move/be in "Active" status like
#  on the command prompt.
#-------------------------------------------------------
waitForActiveStatus() {
  STARTTIME=$SECONDS
  while true; do
    sleep 3
    OUT=$(restCall "GET" "/tm/sys/failover" 2>/dev/null | grep -qi active && echo active || echo no )
    log "waitForActiveStatus(): `echo $OUT`"
    if [[ $(echo $OUT) == "active" ]]; then
      return 0
    fi
    duration=$SECONDS
    if [[ $(($duration - $STARTTIME)) -gt $MAXTIMEOUT ]]; then
      return 1
    fi
  done
}

#-------------------------------------------------------
# Function:  jsonq()
#   Extract JSON key value. Example:
#   {
#    "generation": 1,
#    "items": [
#        {
#            "active": true,
#            "build": "0.0.606",
#            "generation": 1
#        }
#     [,
#   }
# ... | jsonq '["items"][0]["active"]'
# True
#-------------------------------------------------------
jsonq() {
  python -c "import sys,json; input=json.load(sys.stdin); print input$1"
}

#-------------------------------------------------------
# Function: rebootBIGIP()
#-------------------------------------------------------
rebootBIGIP() {
  OUT=$(restCall "POST" "/tm/sys" "{ \"command\": \"reboot\"}")
  log "rebootBIGIP(): `echo $OUT | python -mjson.tool`"
}

#-------------------------------------------------------
# Function: getVersion()
#   Gets the BIGIP version currently active
#-------------------------------------------------------
getVersion() {
  I=0
  OUT=$(restCall "GET" "/tm/cloud/net/software-status" | jsonq "[\"items\"][${I}][\"active\"]")
  log "getVersion(): `echo $OUT`"
  # cycle through all BIGIP partitions looking for the one that is 'active'
  while ! $OUT; do
    I=$((I+1))
    OUT=$(restCall "GET" "/tm/cloud/net/software-status" | jsonq "[\"items\"][${I}][\"active\"]")
    log "getVersion(): `echo $OUT`"
  done
  OUT=$(restCall "GET" "/tm/cloud/net/software-status" | jsonq "[\"items\"][${I}][\"version\"]")
  log "getVersion(): `echo $OUT`"
  echo $OUT | cut -d '.' -f 1,2
}

#-------------------------------------------------------
# Function: saveConfig()
#-------------------------------------------------------
saveConfig() {
  OUT=$(restCall "POST" "/tm/sys/config" '{"command": "save"}')
  log "saveConfig(): `echo $OUT | python -mjson.tool`"
  if [[ $(echo $OUT | jsonq '["kind"]') != "tm:sys:config:savestate" ]]; then
    echo "ERROR! Configuration Save was not successful."
    return 1
  fi
  return 0
}

#-------------------------------------------------------
# Function: setDefaultRoute()
# Sets the default route for Traffic processed by VS's or SelfIP's -- NOT the
# default route on the MGMT port.
#-------------------------------------------------------
setDefaultRoute() {
  OUT=$(restCall "POST" "/tm/net/route" "{ \"name\": \"DefaultRoute\", \"partition\": \"Common\", \
      \"network\": \"default\", \"gw\": \"${1}\" }")
  log "setDefaultRoute(): `echo $OUT | python -mjson.tool`"
  if [[ $(echo $OUT | jsonq '["gw"]') != $1 ]]; then
    echo "ERROR! Default Network Gateway was not successfully set."
    return 1
  fi
  return 0
}

#-------------------------------------------------------
# Function: enableModule()
# $1 => Module name. Can be:  afm, am, apm, asm, avr, fps, gtm, lc, ltm, pem, swg, & vcmp
#-------------------------------------------------------
enableModule() {
  OUT=$(restCall "PUT" "/tm/sys/provision/$1" "{ \"level\": \"nominal\" }")
  log "enableModule(): `echo $OUT | python -mjson.tool`"
}

#-----------------------------------------------------------------------
#--------------------[ Virtual Server Functions ]-----------------------
#-----------------------------------------------------------------------

#-------------------------------------------------------
# Function: addBasicVS()
# $1 => VS Name
# $2 => Dst IP
# $3 => Dst Mask (255.255.255.255 for no mask < v12.0 =>v12.0 = "any")
# $4 => Dst Port (0 for 'any')
# $5 => VS Type (tcp, udp, sctp )
# $6 => Description, if any
#-------------------------------------------------------
addBasicVS() {
  OUT=$(restCall "POST" "/tm/ltm/virtual" "{ \"name\": \"${1}\", \
    \"destination\": \"/Common/${2}:${4}\", \"mask\": \"${3}\", \
    \"ipProtocol\": \"${5}\", \"description\": \"${6}\" }")
  log "addBasicVS(): `echo $OUT | python -mjson.tool`"
  if [[ $(echo $OUT | jsonq '["kind"]') != "tm:ltm:virtual:virtualstate" ]]; then
    echo "ERROR: Virtual Server ${1} was not added correctly."
    return 1
  fi
  return 0
}

#-------------------------------------------------------
# Function:  modifyVS()
# $1 => name of VS
# $2 => JSON payload
#-------------------------------------------------------
modifyVS() {
  OUT=$(restCall "PATCH" "/tm/ltm/virtual/~Common~${1}" "${2}")
  log "modifyVS(): `echo $OUT | python -mjson.tool`"
  if [[ $(echo $OUT | jsonq '["kind"]') != "tm:ltm:virtual:virtualstate" ]]; then
    echo "ERROR: Virtual Server ${1} was not modified correctly."
    return 1
  fi
  return 0
}


#-------------------------------------------------------
# Function: addProfileToVS()
# $1 => VS Name
# $2 => Profile name (http, radius, diameter, ssl, etc.)
#-------------------------------------------------------
addProfileToVS() {
  OUT=$(restCall "POST" "/tm/ltm/virtual/~Common~${1}/profiles" "{ \"name\": \"${2}\", \
    \"fullPath\": \"/Common/${2}\", \"partition\":\"Common\" }")
  log "addProfileToVS(): `echo $OUT | python -mjson.tool`"
  if [[ $(echo $OUT | jsonq '["kind"]') != "tm:ltm:virtual:profiles:profilesstate" ]]; then
    echo "Error: Profile ${2} was not added to Virtual Server ${1} correctly."
    return 1
  fi
  return 0
}
