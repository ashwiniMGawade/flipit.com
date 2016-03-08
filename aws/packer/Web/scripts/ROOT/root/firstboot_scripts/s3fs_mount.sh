#!/bin/bash

S3FS_MOUNTED=s3fs.done
USAGE="Usage: $0 DATA_DEST"

if [ "$#" -ne  1 ]; then
  echo "$USAGE"
  exit 1
fi

DATA_DEST=$1

if [[ ! -f "$S3FS_MOUNTED" ]]
  then
    cat $DATA_DEST| tee -a /etc/fstab
    touch $S3FS_MOUNTED
fi
