$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
require 'simplecov'
require 'rspec/its'

SimpleCov.start do
  add_filter '/spec/'
end

require 'sqlite3'
require 'active_record'

require 'flatter'

require 'support/ar_setup'
require 'support/spec_model'
