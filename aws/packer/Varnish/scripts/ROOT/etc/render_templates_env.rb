require 'etc'
require 'singleton'

class Vars
  include Singleton

  def self.config(&block)
    instance.instance_eval &block
  end

  def self.method_missing(name, *args, &block)
    instance.send(name.to_sym, *args)
  end

  def method_missing(name, *args, &block)
    name = name.to_s

    if name =~ /=$/
      instance_variable_set("@#{name.chop}", args.first)
    else
      instance_variable_get("@#{name}")
    end
  end
end

# Load all files in render_templates_env.d
Dir[File.dirname(__FILE__) + '/render_templates_env.d/*.rb'].each do |file|
  require file
end
