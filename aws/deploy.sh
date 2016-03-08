#!/bin/bash

USAGE="Usage: $0 environment version deployment_name"

if [ "$#" -ne  3 ]; then
  echo "$USAGE"
  exit 1
fi

export AWS_REGION=eu-west-1
export PATH="$PWD/aws/bin:$PATH"

cd aws/packer
source export_secrets.sh
packer build -var "environment=$1" -var "version=$2" kortingscode-www.json |tee stdout.txt
WEB_AMI=$(sed -n "/$AWS_REGION.*ami-.*/p" stdout.txt |awk '{print $2 }')
echo $WEB_AMI
update-cf-params $3 WebAMI=$WEB_AMI
