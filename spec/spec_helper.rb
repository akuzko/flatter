$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
require 'simplecov'
require 'rspec/its'

SimpleCov.start do
  add_filter '/spec/'
end

require 'flatter'
