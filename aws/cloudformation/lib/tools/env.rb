require 'dotenv'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/object/blank'
require 'rspec/expectations'
require 'rspec/collection_matchers'

include RSpec::Matchers

cf_path = File.absolute_path(File.join(__FILE__, '..', '..', '..'))

# Load .env files
Dotenv.load File.join(cf_path, ".env.#{ENV['FLAVOR']}")
Dotenv.load File.join(cf_path, '.env')
Dir[File.join(cf_path, '..', '.env.*.ami')].each { |f| Dotenv.load f }

# Load .rb files
Dir[File.join(cf_path, '**', '*.rb')].each do |f|
  unless File.identical?(f, __FILE__) or
         File.identical?(f, File.join(cf_path, 'lib', 'main.rb'))
    require(f)
  end
end
