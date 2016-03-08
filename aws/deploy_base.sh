#!/bin/bash

USAGE="Usage: $0"

export AWS_REGION=eu-west-1
export PATH="$PWD/aws/bin:$PATH"

cd aws/packer
source export_secrets.sh
packer build kortingscode-www-base.json |tee stdout.txt
BASE_AMI=$(sed -n "/$AWS_REGION.*ami-.*/p" stdout.txt |awk '{print $2 }')
echo $BASE_AMI
