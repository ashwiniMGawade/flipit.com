#!/bin/bash
set -x

WWW_ROOT=/var/www/flipit.com
INCLUDES=$WWW_ROOT/includes
S3_DIR=$WWW_ROOT/shared/public
FILELIST=$INCLUDES/filelist_permissions
PERMISSIONS=775

chmod $PERMISSIONS $S3_DIR
chmod -R $PERMISSIONS $(cat $FILELIST|xargs -I {} echo "$S3_DIR/{}"|xargs echo )

for file in $S3_DIR/*;
do
  if [[ -d "$file" && "$file" == *\/?? ]]; then
    if [[ "$file" == *\/js ]]; then
      chmod -R $PERMISSIONS $file
    fi
    chmod $PERMISSIONS $file
    chmod -R $PERMISSIONS $(cat $FILELIST|xargs -I {} echo "$file/{}"|xargs echo )
  fi
done
