class Job < ActiveRecord::Base
  JOB_STATES = %i(queued encoding failed successful canceled)
end
