#!/bin/bash

[ "$DEBUG" == "1" ] && set -x

set -e

if [ "${GLUSTER_PEER_IP}" != "**ChangeMe**" ]; then
   # This node is not connecting to the cluster yet
   exit 0
fi

if [ "${GLUSTER_PEER_PASSWORD}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "GLUSTER_PEER_PASSWORD" environment variable - Exiting..."
   exit 1
fi

my_rancher_ip=`ip addr show dev eth0 | grep inet | grep 1 0.42 | awk '{print $2}' | xargs -i ipcalc -n {} | grep Address | awk '{print $2}'`

echo "=> Probing peer ${GLUSTER_PEER_IP}..."
gluster peer probe ${GLUSTER_PEER_IP}

echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
gluster volume create ${GLUSTER_VOL} replica 2 ${my_rancher_ip}:/${GLUSTER_BRICK_PATH} ${GLUSTER_PEER_IP}:/${GLUSTER_BRICK_PATH} force

echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
gluster volume start ${GLUSTER_VOL}
