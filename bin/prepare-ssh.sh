#!/bin/bash

[ "$DEBUG" == "1" ] && set -x

set -e
 
echo "root:${VPN_PASSWORD}" | chpasswd
