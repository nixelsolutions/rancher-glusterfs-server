#!/bin/bash

[ "$DEBUG" == "1" ] && set -x

SSH_OPTS="-p 2222 -o ConnectTimeout=4 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# Change root password
if [ "${PASSWORD}" == "**ChangeMe**" ]; then
   export PASSWORD=`pwgen -s 20 1`
fi

#prepare-ssh.sh
/usr/bin/supervisord
prepare-gluster.sh

echo "==========================================="
echo "If you are building a new GlusterFS cluster you will need this password when adding this peer to the cluster: ${PASSWORD}"
echo "==========================================="
