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

  def self.configure
    yield self
  end
end
