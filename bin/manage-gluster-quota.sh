#!/bin/bash

# Exit status = 0 means sucess
# Exit status = 1 means error

set -e

EXIT_OK=0
EXIT_ERROR=1

GLUSTER_CONF_FLAG=/etc/gluster.env
source ${GLUSTER_CONF_FLAG}

[ "$DEBUG" == "1" ] && set -x && set +e

function exit_msg() {
   echo $(basename $0): [From container ${MY_RANCHER_IP}]
   echo "$1"
   exit $2
}

# Params:
# -o OPERATION
# -d DIRECTORY
# -q QUOTA

while getopts ":o:d:s:q:" PARAMS; do
      case $PARAMS in
      o)
           OPERATION=`echo $OPTARG | tr '[:lower:]' '[:upper:]'`
           ;;
      d)
           DIRECTORY=$OPTARG
           ;;
      s)
           SERVICE=$OPTARG
           ;;
      q)
           QUOTA=$OPTARG
           ;;
      esac
done

[ -z "$OPERATION" ] && exit_msg "Error, operation parameter is missing (parameter -o)" $EXIT_ERROR

case $OPERATION in
SUMMARY)
   msg=`gluster volume quota ${GLUSTER_VOL} list | grep "^/"`
   exit_msg "$msg" $?
   ;;
SET)
   [ -z "$DIRECTORY" ] && exit_msg "Error, directory parameter is missing (parameter -d)" $EXIT_ERROR
   [ -z "$QUOTA" ] && exit_msg "Error, quota arameter is missing (parameter -q)" $EXIT_ERROR

   # Set quota on directory
   if ! mount | grep "on /run/gluster/${GLUSTER_VOL} type" >/dev/null; then
      gluster volume quota ${GLUSTER_VOL} list >/dev/null 
      sleep 5
   fi
   if [ ! -d /run/gluster/${GLUSTER_VOL}/${DIRECTORY} ]; then
      mkdir /run/gluster/${GLUSTER_VOL}/${DIRECTORY}
      chown www-data:www-data /run/gluster/${GLUSTER_VOL}/${DIRECTORY}
   fi
   msg=`gluster volume quota ${GLUSTER_VOL} limit-usage /${DIRECTORY} $QUOTA`
   exit_msg "$msg" $?
   ;;
FREE)
   [ -z "$DIRECTORY" ] && exit_msg "Error, directory parameter is missing (parameter -d)" $EXIT_ERROR

   msg=`gluster volume quota ${GLUSTER_VOL} list /${DIRECTORY} | grep "^/" | awk '{print $5}'` 
   exit_msg "$msg" $?
   ;;
USED)
   [ -z "$DIRECTORY" ] && exit_msg "Error, directory parameter is missing (parameter -d)" $EXIT_ERROR

   msg=`gluster volume quota ${GLUSTER_VOL} list /${DIRECTORY} | grep "^/" | awk '{print $4}'`
   exit_msg "$msg" $?
   ;;
TOTAL)
   [ -z "$DIRECTORY" ] && exit_msg "Error, directory parameter is missing (parameter -d)" $EXIT_ERROR

   msg=`gluster volume quota ${GLUSTER_VOL} list /${DIRECTORY} | grep "^/" | awk '{print $2}'`
   exit_msg "$msg" $?
   ;;
DELETE)
   [ -z "$DIRECTORY" ] && exit_msg "Error, directory parameter is missing (parameter -d)" $EXIT_ERROR
   [ -z "$SERVICE" ] && exit_msg "Error, service parameter is missing (parameter -s)" $EXIT_ERROR

   if ! mount | grep "on /run/gluster/${GLUSTER_VOL} type" >/dev/null; then
      gluster volume quota ${GLUSTER_VOL} list >/dev/null
      sleep 5
   fi
   if [ ! -d /run/gluster/${GLUSTER_VOL}/${DIRECTORY} ]; then
      exit_msg "Could not delete directory ${DIRECTORY}/${SERVICE} - Exiting..." 1
   fi
   msg=`rm -rf /run/gluster/${GLUSTER_VOL}/${DIRECTORY}/${SERVICE}`
   exit_msg "$msg" $?
  ;;
*)
   exit_msg "ERROR: unknown operation $OPERATION" $EXIT_ERROR
   ;;
esac
