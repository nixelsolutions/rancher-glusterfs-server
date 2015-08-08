#!/bin/bash

# Exit status = 0 means sucess
# Exit status = 1 means error

set -e

EXIT_OK=0
EXIT_ERROR=1

GLUSTER_CONF_FLAG=/etc/gluster.env
source ${GLUSTER_CONF_FLAG}

[ "$DEBUG" == "1" ] && set -x && set +e

function echo_msg() {
   echo $(basename $0): [From container ${MY_RANCHER_IP}] $1
}

# Params:
# -o OPERATION
# -d DIRECTORY
# -q QUOTA

while getopts ":o:d:q:" PARAMS; do
      case $PARAMS in
      o)
           OPERATION=`echo $OPTARG | tr '[:lower:]' '[:upper:]'`
           ;;
      d)
           DIRECTORY=$OPTARG
           ;;
      q)
           QUOTA=$OPTARG
           ;;
      esac
done

[ -z "$OPERATION" ] && echo_msg "Error, operation parameter is missing (parameter -o)" && exit $EXIT_ERROR
[ -z "$DIRECTORY" ] && echo_msg "Error, directory parameter is missing (parameter -d)" && exit $EXIT_ERROR

case $OPERATION in
SET)
   [ -z "$QUOTA" ] && echo_msg "Error, quota arameter is missing (parameter -q)" && exit $EXIT_ERROR

   # Set quota on directory
   msg=`gluster volume quota ${GLUSTER_VOL} limit-usage /${DIRECTORY} $QUOTA`
   if [ $? -eq 0 ]; then
      echo "SUCCESS: $msg"
      exit $EXIT_OK
   else
      echo "ERROR: $msg"
      exit $EXIT_ERROR
   fi
;;
SHOW)
   msg=`gluster volume quota ${GLUSTER_VOL} list /${DIRECTORY}` 
   if [ $? -eq 0 ]; then
      msg=`echo $msg | grep "^/${DIRECTORY}"`
      echo_msg "SUCCESS: $msg"
      exit $EXIT_OK
   else
      echo_msg "ERROR: $msg"
      exit $EXIT_ERROR
   fi
;;
*)
   echo_msg "ERROR: unknown operation $OPERATION"
   exit $EXIT_ERROR
;;
esac
