class Job < ActiveRecord::Base
  JOB_STATES = %i(queued encoding failed successful canceled)
  has_many :logs

  scope :queued, -> { where(state: 'queued') }

  def encode
    info "starting encode of #{name}"

    update(state: 'encoding')

    if iso
      ISO.mount(input_folder)
        .errback { |data| handle_encode_failed(data) }
        .callback do |data|
          debug "mount command data: #{data}"
          mounted_iso = data['path']

          command = Handbrake.build_command(
            CONFIG['main']['handbrake_base_command'],
            mounted_iso,
            File.join(CONFIG['main']['working_dir'], output_file_name)
          )

          Process.open(command, self, Job.instance_method(:handle_command_output))
            .errback { |process_data| handle_encode_failed(process_data) }
            .callback do |process_data|

              handle_encode_exit(process_data)

              ISO.unmount(mounted_iso)
                .callback { |unmount_data| info "unmounted ISO - #{unmount_data}" }
                .errback { |unmount_data| info "failed to unmount ISO - #{unmount_data}" }
            end
        end
    else
      command = Handbrake.build_command(
        CONFIG['main']['handbrake_base_command'],
        input_folder,
        File.join(CONFIG['main']['working_dir'], output_file_name)
      )

      Process.open(command, self, Job.instance_method(:handle_command_output))
        .callback { |data| handle_encode_exit(data) }
        .errback { |data| handle_encode_failed(data) }
    end
  end

  def self.get_job_to_encode
    if where(state: 'encoding').count > 0
      nil
    else
      queued.first
    end
  end

  private

  def handle_command_output(data)
    # add part to log
    debug "got command output #{data}"
    logs.create if logs.empty?
    log = logs.last
    parts = log.parts
    parts ||= []
    parts.append(data: data, number: parts.length + 1)
    log.update(parts: parts)

    # parse out the progress
    update(progress: Handbrake.get_encode_percent(data))
  end

  def handle_encode_exit(data)
    update(state: 'successful')
    logs.last.update(complete: true)
  end

  def handle_encode_failed(data)
    update(state: 'failed')
    error "encode failed - #{data}"
    logs.last.update(complete: true)
  end
end
