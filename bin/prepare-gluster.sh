#!/bin/bash

[ "$DEBUG" == "1" ] && set -x

set -ex

if [ "${GLUSTER_PEER}" == "**ChangeMe**" ]; then
   # This node is not connecting to the cluster yet
   exit 0
fi

echo "=> Waiting for glusterd to start..."
sleep 10

echo "=> Probing peer ${GLUSTER_PEER}..."
gluster peer probe ${GLUSTER_PEER}

echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
my_rancher_ip=`ip addr show dev eth0 | grep inet | grep 10.42 | awk '{print $2}' | xargs -i ipcalc -n {} | grep Address | awk '{print $2}'`
gluster volume create ${GLUSTER_VOL} replica ${GLUSTER_REPLICA} ${my_rancher_ip}:${GLUSTER_BRICK_PATH} ${GLUSTER_PEER}:${GLUSTER_BRICK_PATH} force

echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
gluster volume start ${GLUSTER_VOL}
