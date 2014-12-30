collection @jobs => :jobs
attributes :id, :name, :input_folder, :input_file_name, :output_file_name, :state, :iso, :progress, :created_at, :updated_at
node(:logs) { |job| job.log_ids }
