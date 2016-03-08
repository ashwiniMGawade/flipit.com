#!/usr/bin/env ruby

BAMBOO_ENV_PREFIX="bamboo_"
OUTFILE=".env"
PRIVATE_VARS_IDS=["password", "secret"]

def is_private_var(var)
  PRIVATE_VARS_IDS.map { |id| var.include?(id) }.reduce{|r,e| r || e }
end

def bamboo_vars(varset)
  vars = varset.select { |key, _| key.start_with?(BAMBOO_ENV_PREFIX) }
  Hash[vars.map {|k, v| [k.gsub( /^#{BAMBOO_ENV_PREFIX}/, ''), v] }]
end

def filter_private(varset, filter=false)
  if filter
    varset.select { |key,_| is_private_var(key) }
  else
    varset.select { |key,_| not is_private_var(key) }
  end
end

def key_equals_value_format(input_hash)
  input_hash.map { |key,value| "#{key}=#{value}"}
end

def write_env(outfile, varset)
  File.open(outfile, "w+") do |f|
    f.puts(varset)
  end
end

def run
  bamboo_varset = bamboo_vars(ENV)
  public_varset = filter_private(bamboo_varset)
  private_varset = filter_private(bamboo_varset, true)
  env = key_equals_value_format(public_varset)
  private_env = key_equals_value_format(private_varset)
  write_env(OUTFILE, env)
  write_env("#{OUTFILE}.private", private_env)
end

run
