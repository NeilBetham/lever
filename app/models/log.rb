class Log < ActiveRecord::Base
  belongs_to :job
  serialize :parts
end
