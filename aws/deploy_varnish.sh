#!/bin/bash

USAGE="Usage: $0 deployment_name"

if [ "$#" -ne  1 ]; then
  echo "$USAGE"
  exit 1
fi

export AWS_REGION=eu-west-1
export PATH="$PWD/aws/bin:$PATH"

cd aws/packer
source export_secrets.sh
packer build kortingscode-varnish.json |tee stdout.txt
VARNISH_AMI=$(sed -n "/$AWS_REGION.*ami-.*/p" stdout.txt |awk '{print $2 }')
echo $VARNISH_AMI
update-cf-params $1 VarnishAMI=$VARNISH_AMI
