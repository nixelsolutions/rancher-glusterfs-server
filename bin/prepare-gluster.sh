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
   echo "=> This peer is already part of Gluster Cluster, nothing to do..."
   exit 0
fi

echo "=> Probing peer ${GLUSTER_PEER}..."
ping -c 10 ${GLUSTER_PEER} >/dev/null 2>&1
gluster peer probe ${GLUSTER_PEER}

echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
my_rancher_ip=`echo ${RANCHER_IP} | awk -F\/ '{print $1}'`
gluster volume create ${GLUSTER_VOL} replica ${GLUSTER_REPLICA} ${my_rancher_ip}:${GLUSTER_BRICK_PATH} ${GLUSTER_PEER}:${GLUSTER_BRICK_PATH} force

echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
gluster volume start ${GLUSTER_VOL}
