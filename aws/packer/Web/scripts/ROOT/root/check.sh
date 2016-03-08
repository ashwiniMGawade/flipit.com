#!/bin/bash
USAGE="Usage: $0 [-t CHECK_INTERVAL] [ -p PROCESS_NAME] [-m MOUNT]"
INTERVAL=10
PROCESS="s3fs"
MOUNT=/var/www/flipit.com/shared


while getopts "ht:p:m:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    t)
      INTERVAL=$OPTARG
      ;;
    p)
      PROCESS=$OPTARG
      ;;
  m)
    MOUNT=$OPTARG
    ;;
  esac
done

echo "[`date`] Starting check for process $PROCESS"
echo "[`date`] Interval set to $INTERVAL seconds"
echo "[`date`] Mount point set to $MOUNT"

while true;
do
  if [[ $(ps aux|grep "$PROCESS.*$MOUNT"|wc -l) -lt 2 ]]
  then
    sleep 2
    if [[ $(ps aux|grep "$PROCESS.*$MOUNT"|wc -l) -lt 2 ]]
    then
      echo "[`date`] Process $PROCESS is not running..."
      echo "[`date`] Remounting $MOUNT"
      umount $MOUNT; mount $MOUNT
    fi
  fi
  sleep $INTERVAL
done
