require 'active_support'
require 'active_support/core_ext'

require 'active_model'

require 'flatter/version'
require 'flatter/mapping'
require 'flatter/mapper'
require 'flatter/extension'

module Flatter
  extend Extension::Registrar

  use :scribe, require: 'flatter/mapping/scribe'

  mattr_accessor :default_mapper_class

  def self.configure
    yield self
  end

  def self.extends(klass, *modules)
    if block_given?
      _module = Module.new(&Proc.new)
      klass.const_set("FlatterExtension", _module)
      modules.push _module
    end
    modules.each{ |mod| klass.send(:include, mod) }
  end
end
