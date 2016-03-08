#!/bin/bash

HEALTHCHECK_URL=localhost/health.php
CHECK_INTERVAL=60 #seconds
RETRIES=8

USAGE="Usage: $0 [-t CHECK_INTERVAL] [ -u URL]"

while getopts "ht:u:" opt; do
  case $opt in
    h)
      echo "$USAGE"
      exit 0
      ;;
    t)
      CHECK_INTERVAL=$OPTARG
      ;;
    u)
      HEALTHCHECK_URL=$OPTARG
      ;;
  esac
done

health_check() {
  curl -I $HEALTHCHECK_URL|awk 'NR==1 {print $2}'
}

recover() {
  service apache2 restart
}

unhealthy_count=0;
while true; do
  response=$(health_check)
  if [ "$response" == "200" ]; then
    unhealthy_count=0
  else
    if [ $unhealthy_count -ge $RETRIES ]; then
      shutdown -h now
    fi
    unhealthy_count=$((unhealthy_count+1))
    recover
  fi
  sleep $CHECK_INTERVAL
done
