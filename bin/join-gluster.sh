#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x

function check_if_already_joined {
   # Check if I'm part of the cluster
   NUMBER_OF_PEERS=`gluster peer status | grep "Number of Peers:" | awk -F: '{print $2}'`
   if [ ${NUMBER_OF_PEERS} -ne 0 ]; then
      # This container is already part of the cluster
      echo "=> This container is already joined with nodes ${GLUSTER_PEERS}, skipping joining ..."
      exit 0
   fi
}

echo "=> Waiting for glusterd to start..."
sleep 10

check_if_already_joined

# Join the cluster - choose a suitable container
ALIVE=0
for PEER in ${GLUSTER_PEERS}; do
   # Skip myself
   if [ "${MY_RANCHER_IP}" == "${PEER}" ]; then
      continue
   fi
   echo "=> Checking if I can reach gluster container ${PEER} ..."
   if sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "hostname" >/dev/null 2>&1; then
      echo "=> Gluster container ${PEER} is alive"
      ALIVE=1
      break
   else
      echo "*** Could not reach gluster container ${PEER} ..."
   fi 
done

if [ ${ALIVE} -eq 0 ]; then
   echo "Could not reach any GlusterFS container from this list: ${GLUSTER_PEERS} - Maybe I am the first node in the cluster? Well, I keep waiting for new containers to join me ..."
   exit 0
fi

# If PEER has requested me to join him, just wait for a while
SEMAPHORE_FILE=/tmp/adding-gluster-node.${PEER}
if [ -e ${SEMAPHORE_FILE} ]; then
   echo "=> Seems like peer ${PEER} has just requested me to join him"
   echo "=> So I'm waiting for 60 seconds to finish it..."
   sleep 60
fi
check_if_already_joined

echo "=> Joining cluster with container ${PEER} ..."
sshpass -p ${ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "add-gluster-peer.sh ${MY_RANCHER_IP}"
if [ $? -eq 0 ]; then
   echo "=> Successfully joined cluster with container ${PEER} ..."
else
   echo "=> Error joining cluster with container ${PEER} ..."
fi
