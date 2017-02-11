require 'flatter/extensions/multiparam'
require 'flatter/extensions/order'
require 'flatter/extensions/skipping'

if defined? ActiveRecord
  require 'flatter/extensions/active_record'
end
