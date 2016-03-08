#!/bin/bash
set -x

# Export Keys for various services
export PACKER_AWS_ACCESS_KEY_ID=$bamboo_packer_aws_access_key_id
export S3FS_AWS_ACCESS_KEY_ID=$bamboo_s3fs_aws_access_key_id
export S3CMD_AWS_ACCESS_KEY_ID=$bamboo_s3cmd_aws_access_key_id
export MASTER_AWS_ACCESS_KEY_ID=$bamboo_master_aws_access_key_id

set +x # hide secrets in output
export PACKER_AWS_SECRET_ACCESS_KEY=$bamboo_packer_aws_access_password
export S3FS_AWS_SECRET_ACCESS_KEY=$bamboo_s3fs_aws_access_password
export S3CMD_AWS_SECRET_ACCESS_KEY=$bamboo_s3cmd_aws_access_password
export MASTER_AWS_SECRET_ACCESS_KEY=$bamboo_master_aws_access_password
set -x

# Export other env variables
export AWS_REGION=$bamboo_aws_region
export ENVIRONMENT=$bamboo_build_environment
export RELEASE=$bamboo_build_release
export INSTANCE_TYPE=$bamboo_packer_instance_type
export NAME=flipit-${bamboo_layer}-${ENVIRONMENT}-${RELEASE}

PACKER_DIR=aws/packer

git config --global user.email "bamboo@webflight.com"
git config --global user.name "BambooBot"

cd $PACKER_DIR

if [ "$bamboo_build_from_scratch" = true ] ; then
  echo "Building AMI from scratch"
  export SOURCE_AMI=$(cat .${bamboo_layer}_source_ami_base)
  packer build -var "INSTANCE_TYPE=${INSTANCE_TYPE}" -var "SOURCE_AMI=${SOURCE_AMI}" kortingscode-${bamboo_layer}.json |tee stdout.txt
  FINAL_AMI=$(sed -n "/$AWS_REGION.*ami-.*/p" stdout.txt |awk '{print $2 }')
  echo $FINAL_AMI| tee .${bamboo_layer}_source_ami

  if [ -n "$FINAL_AMI" ]; then
    # Commit new base AMI
    git add .${bamboo_layer}_source_ami
    git commit -m "Updating ${bamboo_layer} source AMI  to ${FINAL_AMI}"
    git push origin $bamboo_repository_git_branch
  fi
fi

echo "Building AMI from prepared source AMI"
ls -la
export SOURCE_AMI=$(cat .${bamboo_layer}_source_ami)
packer build -var "INSTANCE_TYPE=${INSTANCE_TYPE}" -var "SOURCE_AMI=${SOURCE_AMI}" kortingscode-${bamboo_layer}.json |tee stdout.txt
FINAL_AMI=$(sed -n "/$AWS_REGION.*ami-.*/p" stdout.txt |awk '{print $2 }')
echo $FINAL_AMI| tee .${bamboo_layer}_ami

if [ -n "$FINAL_AMI" ]; then
  # Commit new base AMI
  git add .${bamboo_layer}_ami
  git commit -m "Updating ${bamboo_layer} AMI to ${FINAL_AMI}"
  git push origin $bamboo_repository_git_branch
fi
