#!/bin/bash

# Exit status = 0 means the peer was successfully joined
# Exit status = 1 means there was an error while joining the peer to the cluster

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

source ${GLUSTER_CFG_FILE}
PEER=$1

function echo() {
   builtin echo $(basename $0): [From container ${MY_RANCHER_IP}] $1
}

function detach() {
   echo "=> Some error ocurred while trying to add peer ${PEER} to the cluster - detaching it ..."
   gluster peer detach ${PEER} force
   exit 1
}

if [ -z "${PEER}" ]; then
   echo "=> ERROR: I was supposed to add a new gluster peer to the cluster but no IP was specified, doing nothing ..."
   exit 1
fi

echo "=> Checking if I can reach gluster container ${PEER} ..."
if sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "hostname" >/dev/null 2>&1; then
   echo "=> Gluster container ${PEER} is alive"
else
   echo "*** Could not reach gluster master container ${PEER} - exiting ..."
   exit 1
fi

# Check how many peers are already joined in the cluster - needed to add a replica
NUMBER_OF_REPLICAS=`gluster volume info ${GLUSTER_VOL} | grep "Number of Bricks:" | awk '{print $6}'`

# Check if peer container is already part of the cluster
PEER_STATUS=`gluster peer status | grep -A2 "Hostname: ${PEER}$" | grep State: | awk -F: '{print $2}'`
if echo "${PEER_STATUS}" | grep "Peer Rejected"; then
   if gluster volume info ${GLUSTER_VOL} | grep ": ${PEER}:${GLUSTER_BRICK_PATH}$" >/dev/null; then
      echo "=> Peer container ${PEER} was part of this cluster but must be dropped now ..."
      gluster --mode=script volume remove-brick ${GLUSTER_VOL} replica $((NUMBER_OF_REPLICAS-1)) ${PEER}:${GLUSTER_BRICK_PATH} force
      sleep 5
   fi
      gluster peer detach ${PEER} force
      sleep 5
fi

# Probe the peer
if ! echo "${PEER_STATUS}" | grep "Peer in Cluster" >/dev/null; then
    # Peer probe
    echo "=> Probing peer ${PEER} ..."
    gluster peer probe ${PEER}
    sleep 5
fi

# Check how many peers are already joined in the cluster - needed to add a replica
NUMBER_OF_REPLICAS=`gluster volume info ${GLUSTER_VOL} | grep "Number of Bricks:" | awk '{print $6}'`
# Create the volume
if ! gluster volume list | grep "^${GLUSTER_VOL}$" >/dev/null; then
   echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
   gluster volume create ${GLUSTER_VOL} replica 2 ${MY_RANCHER_IP}:${GLUSTER_BRICK_PATH} ${PEER}:${GLUSTER_BRICK_PATH} force || detach
   sleep 1
fi

# Start the volume
if ! gluster volume status ${GLUSTER_VOL} >/dev/null; then
   echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
   gluster volume start ${GLUSTER_VOL}
   sleep 1
fi

if ! gluster volume info ${GLUSTER_VOL} | grep ": ${PEER}:${GLUSTER_BRICK_PATH}$" >/dev/null; then
   echo "=> Adding brick ${PEER}:${GLUSTER_BRICK_PATH} to the cluster (replica=$((NUMBER_OF_REPLICAS+1)))..."
   gluster volume add-brick ${GLUSTER_VOL} replica $((NUMBER_OF_REPLICAS+1)) ${PEER}:${GLUSTER_BRICK_PATH} force || detach
fi

exit 0