require 'rubygems'
require 'bundler'
Bundler.setup

require 'cloudformer'
require 'dotenv'
require 'rugged'
require 'mkmf'
require 'aws-sdk'
require 'digest/sha1'
require 'webflight-tasks/tasks'
require 'fileutils'

Dotenv.load ".env.private"
Dotenv.load ".env"

CLOUDFORMATION_VAR_PREFIX="CF_"
SNAPSHOT_PATTERN="flipit-cf-production"


def stack_is_deployed(stack_name)
  cfm ||= AWS::CloudFormation.new
  cfm.stacks.select { |s| s.name == stack_name }.any?
end

def find_latest_rds_snapshot(pattern)
  rds ||=AWS::RDS.new
  matches = rds.db_snapshots.select { |s| s.db_snapshot_identifier.include? pattern }
  snapshot = matches.inject { |r,e| r.created_at > e.created_at ? r : e }
  snapshot.db_snapshot_identifier
end

def current_rds_snapshot(stack_name)
  cfm ||= AWS::CloudFormation.new
  cfm.stacks[stack_name].parameters['RdsSnapshot']
end

def current_param_value(stack_name, param)
  cfm ||= AWS::CloudFormation.new
  cfm.stacks[stack_name].parameters[param]
end

def parameter_defined?(param_set, param)
  param_set[param] and not param_set[param].empty?
end

def stack_in_hibernation?(stack_name)
  cfm ||= AWS::CloudFormation.new
  cfm.stacks[stack_name].parameters['Hibernate'] == 'true'
end

def generated_params(params)
  generated = {}
  if not stack_is_deployed(stack_name) and not parameter_defined?(params, 'RdsSnapshot')
    generated['RdsSnapshot'] = find_latest_rds_snapshot(SNAPSHOT_PATTERN)
  elsif stack_is_deployed(stack_name)
    if stack_in_hibernation?(stack_name)
      generated['RdsSnapshot'] = find_latest_rds_snapshot(SNAPSHOT_PATTERN)
    elsif not parameter_defined?(params, 'RdsSnapshot')
      generated['RdsSnapshot'] = current_rds_snapshot(stack_name)
    end
  end

  ['Web','Varnish'].each do |layer|
    if not parameter_defined?(ENV, "#{layer}AMI")
      Dotenv.load "amis/.env.#{layer}.ami"
      Dotenv.load "aws/.env.#{layer}.ami"
      generated["#{layer}AMI"] = ENV["#{layer}AMI"]
    end
  end
  $stderr.puts "Generated parameters: #{generated}"
  generated
end

def deployment_parameters
  Dotenv.load "aws/.env.toggle"
  if ENV['TOGGLE_STATE'] == 'true'
    cfm ||= AWS::CloudFormation.new
    params = cfm.stacks[stack_name].parameters
    if parameter_defined?(ENV, 'Hibernate')
      params['Hibernate'] = ENV['Hibernate']
    else
      params['Hibernate'] = current_param_value(stack_name, 'Hibernate')=="true" ? "false" : "true"
    end
  else
    params = ENV.select { |k,v| k.start_with? CLOUDFORMATION_VAR_PREFIX }
    params = Hash[params.map {|k, v| [k.gsub( /^#{CLOUDFORMATION_VAR_PREFIX}/, ''), v] }]
    params.merge! generated_params(params)
  end
  params
end

def find_amis(commit, source_ami)
  ec2 = AWS::EC2.new
  $stderr.puts "Searching AMI by GIT_COMMIT=#{commit} and SOURCE_AMI=#{source_ami}"
  amis = ec2.images.with_tag('GIT_COMMIT', commit).with_tag('SOURCE_AMI', source_ami).map {|x| x}
end

def pack_ami(name, base=false)
  Dotenv.load "aws/packer/#{name}/.env"
  source_ami = ENV['SOURCE_AMI']
  check_packer_settings

  this_repo = Rugged::Repository.discover()
  repo = Rugged::Repository.discover(".")

  commit = this_repo.head.target.oid.to_s
  amis = find_amis(commit, source_ami)

  if amis.empty?
    sh "packer build -var 'GIT_BRANCH=#{this_repo.head.name}' -var 'GIT_COMMIT=#{commit}' -var 'NAME=#{name}' -var 'SOURCE_AMI=#{source_ami}'  aws/packer/#{name}/packer#{base ? "-base" : "" }.json"
    amis = find_amis(commit, source_ami)
    if amis.empty?
      abort "ERROR: No AMI could be found for commit '#{commit}' with source AMI '#{source_ami}'!"
    end

    Dotenv.load "aws/.env.#{name}.ami"
    if amis.first.id != ENV["#{name}AMI"]
      File.open("aws/.env.#{name}.ami", 'w') do |f|
        f.write "#{name}AMI = #{amis.first.id}\n"
      end
    end
  else
    $stderr.puts "Found AMI '#{amis.map(&:id).join(', ')}' for '#{name}' commit '#{commit}' with source AMI '#{source_ami}'"
    Dotenv.load "aws/.env.#{name}.ami"
    if amis.first.id != ENV["#{name}AMI"]
      File.open("aws/.env.#{name}.ami", 'w') do |f|
        f.write "#{name}AMI = #{amis.first.id}\n"
      end
    end
  end

  if amis.first.id != ENV["#{name}AMI"] and ENV['build_from_scratch'] == "false"
    git_commit("aws", ".env.#{name}.ami")
    git_push
  end
end

def git_push()
  $stderr.puts "Pushing to remote repository"
  system "git remote add flipit.com git@bitbucket.org:webflight/flipit.com.git"
  system "git fetch flipit.com"
  system "cd aws && git push --set-upstream flipit.com #{ENV['planRepository_branchName']}"
end

def git_config()
  system "git config --global user.name \"Bamboo\""
  system "git config --global user.email bamboo@webflight.com"
  system "git config --global push.default simple"
end

def git_commit(path, file)
  $stderr.puts "Commiting file #{path}/#{file}"
  system "cd #{path} && git add #{file} && git commit -m \"Automated update for file #{file}\""
end

def check_aws_credentials
  ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY'].each do |var|
    abort "ERROR: Please set '#{var}' environment variable" unless ENV[var] and !ENV[var].strip.empty?
  end
end

def check_packer_settings
  ['SOURCE_AMI'].each do |var|
    abort "ERROR: Please set '#{var}' environment variable" unless ENV[var] and !ENV[var].strip.empty?
  end
end

def is_dirty?(repo, abort_if_dirty = true)
  dirty_items = []
  repo.status { |x| dirty_items << x unless repo.path_ignored? x }

  dirty = dirty_items.length > 0

  if dirty
    message = "Uncommitted change#{'s' if dirty_items.length > 1} in '#{repo.workdir}':\n  - '#{dirty_items.join("'\n  - '")}'"
    if abort_if_dirty
      abort "Error: #{message}"
    else
      $stderr.puts message
    end
  end
  return dirty
end

def packer_build(name)
  if ENV['build_from_scratch'] == "true"
    pack_ami(name, true)
  end
  pack_ami(name)
end


Rake::Task["packer:build_all"].clear
Rake::Task["packer:build"].clear
Rake::Task["apply"].clear

namespace :packer do
  desc "Build all AMIs using Packer"
  task :build_all do |t|
    Dir.entries('aws/packer').select{|x| File.directory? File.join('aws/packer', x)}.select{|x| !['.', '..'].include? x}.each do |packer_name|
      sh "rake packer:build\[#{packer_name}\]"
    end
  end

  desc "Build an AMI using Packer"
  task :build, [:packer_name] do |t, args|

    Dotenv.load ".env"
    Dotenv.load ".env.private"

    git_config
    check_aws_credentials
    $stderr.puts "Performing packer build for #{args['packer_name']}"
    packer_build(args['packer_name'])
    $stderr.puts "Packer build step finished"

  end
end


task default: [ :generate_template ]

desc "Generate CloudFormation template"
task :generate_template do
  repo = Rugged::Repository.discover("./")
  commit = repo.head.target.oid.to_s

  Rake::Task["cloudformation:build"].invoke('aws')

  ENV['DEPLOYMENT_GIT_COMMIT'] = commit
  cf_path="aws/cloudformation"
  FileUtils.cp("aws/build/#{ENV['STACK_NAME']}.json", "aws/cloudformation/src/")
  sh "cd #{cf_path} && npm install"
  sh "cd #{cf_path} && npm start"
  FileUtils.rm("aws/cloudformation/src/#{ENV['STACK_NAME']}.json")

end

desc "Togle Stack State"
task :toggle_stack_state, [:stack, :hibernate] do |t, args|
  File.open("aws/.env.toggle", 'w') do |f|
    f.write "TOGGLE_STATE = true\n"
    f.write "Hibernate= #{args[:hibernate]}\n" if args[:hibernate]
    f.write "deploy_environment = #{args[:stack]}\n"
  end

  Rake::Task["apply"].invoke(t)
  File.delete("aws/.env.toggle")
end

task :diff do
  path = "aws/cloudformation/build"
  cur_template = "#{path}/#{stack_name}.current.template"
  new_template = "#{path}/#{stack_name}.template"
  cur_json     = "#{path}/#{stack_name}.current.json"
  new_json     = "#{path}/#{stack_name}.json"

  cur = cur_template
  new = new_template
  $stderr.puts "Stack name is #{stack_name}"
  cfm = AWS::CloudFormation.new
  stack = cfm.stacks[stack_name]

  File.open(cur_template, 'w') { |f| f.write(stack.template) }

  if find_executable0 'jq'
    sh "jq -S '.' < #{cur_template} > #{cur_json}"
    cur = cur_json
    new = new_json
  end

  sh("#{ENV['DIFF'] || 'diff'} #{cur} #{new}") { |ok, res| true }
end

def stack_name
  parameter_defined?(ENV, "deploy_environment") ? "flipit-#{ENV['deploy_environment'].downcase}" : ""
end

Cloudformer::Tasks.new(stack_name) do |t|
  t.template = "aws/cloudformation/build/#{stack_name}.template"
  t.capabilities = [ 'CAPABILITY_IAM' ]
  t.policy = "aws/cloudformation/#{stack_name}-policy.json"
  t.parameters = deployment_parameters
  t.bucket = ENV['CLOUDFORMATION_BUCKET']
end
