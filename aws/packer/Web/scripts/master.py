#!/usr/bin/python

import boto.ec2.autoscale
import urllib2

AWS_REGION='eu-west-1'
ASG_NAME="www"

def instance_id():
  return urllib2.urlopen("http://169.254.169.254/latest/meta-data/instance-id").read()

def autoscaling_instances():
  autoscale = boto.ec2.autoscale.connect_to_region(AWS_REGION)
  instances = autoscale.get_all_autoscaling_instances()
  www_instances = filter(lambda x: ASG_NAME in x.group_name, instances)
  return www_instances

def master_instance_id(instances):
  master_instance = reduce(lambda x,y: x if x.instance_id > y.instance_id else y, instances)
  return master_instance.instance_id

def current_is_master(current, master):
  return current == master

def run():
  www_instances =  autoscaling_instances()
  master_id = master_instance_id(www_instances)
  current_id = instance_id()
  if(current_is_master(current_id, master_id)):
    return(0)
  else:
    exit(1)

run()
