#!/bin/bash
USAGE="Usage: $0 [-t CHECK_INTERVAL] [ -m MOUNT] [ -q QUOTA (%)]"
INTERVAL=30
MOUNT=/mnt
QUOTA=70
DIR="img.flipit.com"

while getopts "ht:m:q:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    t)
      INTERVAL=$OPTARG
      ;;
    m)
      MOUNT=$OPTARG
      ;;
    q)
      QUOTA=$OPTARG
      ;;      
  esac
done

echo "[`date`] Starting check for process $PROCESS"
echo "[`date`] Interval set to $INTERVAL seconds"
echo "[`date`] Mount point set to $MOUNT"

while true;
do
  use=$(df|grep $MOUNT|awk '{print $5'})
  use=${use%%\%}
  if [[ $use -gt $QUOTA ]]
  then
    echo "[`date`] Disk usage for $MOUNT is larger than $QUOTA%"
    echo "[`date`] Removing specific contents of $MOUNT"
    if [[ ! -z "$MOUNT" && "$MOUNT" != "/" ]] 
      then
        cd $MOUNT && rm -rf $MOUNT/$DIR
    fi
  fi
  sleep $INTERVAL
done
