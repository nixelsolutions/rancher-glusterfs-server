#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x

if [ "${GLUSTER_PEER}" == "**ChangeMe**" ]; then
   # This node is not connecting to the cluster yet
   exit 0
fi

echo "=> Waiting for glusterd to start..."
sleep 10

if gluster peer status | grep ${GLUSTER_PEER} >/dev/null; then
   echo "=> This peer is already joined with node ${GLUSTER_PEER}, skipping..."
else
   echo "=> Probing peer ${GLUSTER_PEER}..."
   gluster peer probe ${GLUSTER_PEER}
fi

sleep 2

if gluster volume list | grep "^${GLUSTER_VOL}$" >/dev/null; then
   echo "=> The volume ${GLUSTER_VOL} is already created, skipping..."
else
   echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
   my_rancher_ip=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
   gluster volume create ${GLUSTER_VOL} replica ${GLUSTER_REPLICA} ${my_rancher_ip}:${GLUSTER_BRICK_PATH} ${GLUSTER_PEER}:${GLUSTER_BRICK_PATH} force
fi

sleep 1

if gluster volume status ${GLUSTER_VOL} >/dev/null; then
   echo "=> The volume ${GLUSTER_VOL} is already started, skipping..."
else
   echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
   gluster volume start ${GLUSTER_VOL}
fi
