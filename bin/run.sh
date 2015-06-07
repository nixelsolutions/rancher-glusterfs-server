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

# Required variables to work
sleep 5
export GLUSTER_PEERS=`dig +short $SERVICE_NAME`
export MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`

# Prepare a shell to initialize docker environment variables for ssh
echo "#!/bin/bash" > ${GLUSTER_CFG_FILE}
echo "ROOT_PASSWORD=\"${ROOT_PASSWORD}\"" >> ${GLUSTER_CFG_FILE}
echo "SSH_PORT=\"${SSH_PORT}\"" >> ${GLUSTER_CFG_FILE}
echo "SSH_USER=\"${SSH_USER}\"" >> ${GLUSTER_CFG_FILE}
echo "SSH_OPTS=\"${SSH_OPTS}\"" >> ${GLUSTER_CFG_FILE}
echo "GLUSTER_VOL=\"${GLUSTER_VOL}\"" >> ${GLUSTER_CFG_FILE}
echo "GLUSTER_BRICK_PATH=\"${GLUSTER_BRICK_PATH}\"" >> ${GLUSTER_CFG_FILE}
echo "DEBUG=\"${DEBUG}\"" >> ${GLUSTER_CFG_FILE}
echo "MY_RANCHER_IP=\"${MY_RANCHER_IP}\"" >> ${GLUSTER_CFG_FILE}

join-gluster.sh &
/usr/bin/supervisord
