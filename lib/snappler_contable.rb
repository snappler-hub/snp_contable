require "snappler_contable/ext/string"
require "snappler_contable/snappler_contable_active_record_extension"
require "snappler_contable/snappler_contable"
require "snappler_contable/tree_node"

module SnapplerContable

  # To setup run $ rails generate snappler_contable:install
  def self.setup
    yield self
  end

  class ActiveRecord::Base  
    include SnapplerContableActiveRecordExtension
  end
  
end

require 'snappler_contable/railtie' if defined?(Rails)
