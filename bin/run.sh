#!/bin/bash

set -e 

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${ROOT_PASSWORD}" == "**ChangeMe**" -o -z "${ROOT_PASSWORD}" ]; then
   echo "*** ERROR: you need to define ROOT_PASSWORD environment variable - Exiting ..."
   exit 1
fi

if [ "${SERVICE_NAME}" == "**ChangeMe**" -o -z "${SERVICE_NAME}" ]; then
   echo "*** ERROR: you need to define SERVICE_NAME environment variable - Exiting ..."
   exit 1
fi

# Required stuff to work
sleep 5
export GLUSTER_PEERS=`dig +short ${SERVICE_NAME}`
if [ -z "${GLUSTER_PEERS}" ]; then
   echo "*** ERROR: Could not determine which containers are part of this service."
   echo "*** Is this service named \"${SERVICE_NAME}\"? If not, please regenerate the service"
   echo "*** and add SERVICE_NAME environment variable which value should be equal to this service name"
   echo "*** Exiting ..."
   exit 1
fi
export MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
if [ -z "${MY_RANCHER_IP}" ]; then
   echo "*** ERROR: Could not determine this container Rancher IP - Exiting ..."
   exit 1
fi
echo "root:${ROOT_PASSWORD}" | chpasswd

# Prepare a shell to initialize docker environment variables for ssh
echo "#!/bin/bash" > /etc/gluster.env
echo "ROOT_PASSWORD=\"${ROOT_PASSWORD}\"" >> /etc/gluster.env
echo "SSH_PORT=\"${SSH_PORT}\"" >> /etc/gluster.env
echo "SSH_USER=\"${SSH_USER}\"" >> /etc/gluster.env
echo "SSH_OPTS=\"${SSH_OPTS}\"" >> /etc/gluster.env
echo "GLUSTER_VOL=\"${GLUSTER_VOL}\"" >> /etc/gluster.env
echo "GLUSTER_BRICK_PATH=\"${GLUSTER_BRICK_PATH}\"" >> /etc/gluster.env
echo "DEBUG=\"${DEBUG}\"" >> /etc/gluster.env
echo "MY_RANCHER_IP=\"${MY_RANCHER_IP}\"" >> /etc/gluster.env

join-gluster.sh &
/usr/bin/supervisord
