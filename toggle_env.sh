#!/bin/bash

export AWS_REGION=eu-west-1
DEFAULT_REPO=git@bitbucket.org:webflight/flipit.com.git
USAGE="Usage: $0 stack_name [repo_url]"

if [ "$#" -lt  1 ]; then
  echo "$USAGE"
  exit 1
fi

STACK_NAME=$1

[[ -n "$2" ]] && REPO_PATH=$2 || REPO_PATH=$DEFAULT_REPO

git clone $REPO_PATH
REPO_NAME=${REPO_PATH##*/}
REPO_NAME=${REPO_NAME%%.git}

cd $REPO_NAME
rvm use --create 2.1.1@deploy
bundle install

rake toggle_stack_state['acceptance']
