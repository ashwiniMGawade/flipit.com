#!/usr/bin/env ruby

require 'cloudformer'
require 'dotenv'
require 'aws-sdk'
 require "resolv-replace.rb"

Dotenv.load ".env"
Dotenv.load ".env.private"

CLOUDFORMATION_VAR_PREFIX="CF_"
SNAPSHOT_PATTERN="flipit-production"

def deployment_parameters
 params ||= ENV.select { |k,v| k.start_with? CLOUDFORMATION_VAR_PREFIX }
 params ||= Hash[params.map {|k, v| [k.gsub( /^#{CLOUDFORMATION_VAR_PREFIX}/, ''), v] }]
end

def stack_is_deployed(stack_name)
  cfm ||= AWS::CloudFormation.new
  cfm.stacks.select { |s| s.name == stack_name }.any?
end

def find_latest_rds_snapshot(pattern)
  rds ||=AWS::RDS.new
  matches = rds.db_snapshots.select { |s| s.db_snapshot_identifier.include? pattern }
  matches.inject { |r,e| r.created_at > e.created_at ? r : e }
end

def run
  params = deployment_parameters
  if not stack_is_deployed(ENV['stack_name']) and not params['RdsSnapshot']
    params['RdsSnapshot'] = find_latest_rds_snapshot(SNAPSHOT_PATTERN)
  end
end

run
