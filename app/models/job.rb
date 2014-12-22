class Job < ActiveRecord::Base
  JOB_STATES = %i(queued encoding failed successful canceled)
  has_many :logs

  scope :queued, -> { where(state: 'queued') }

  def encode
    info "starting encode of #{name}"

    if iso
      ISO.mount(input_folder)
        .errback { |data| handle_encode_failed(data) }
        .callback do |data|
          mounted_iso = JSON.parse(data)['path']

          command = Handbrake.build_command(
            CONFIG['main']['handbrake_base_command'],
            mounted_iso,
            File.join(CONFIG['main']['working_dir'], output_file_name)
          )

          Process.open(command, handle_command_output)
            .callback { |data| handle_encode_exit(data) }
            .errback { |data| handle_encode_failed(data) }
        end
    else
      command = Handbrake.build_command(
        CONFIG['main']['handbrake_base_command'],
        input_file,
        File.join(CONFIG['main']['working_dir'], output_file_name)
      )

      Process.open(command, handle_command_output)
        .callback { |data| handle_encode_exit(data) }
        .errback { |data| handle_encode_failed(data) }
    end
  end

  def self.get_job_to_encode
    if where(state: encoding).count > 0
      none
    else
      queued.first
    end
  end

  private

  def handle_command_output(data)
    # add part to log
    logs.create if logs.empty?
    log = logs.last
    parts = log.parts
    parts.append(data: data, number: parts.length)
    log.update(parts: parts)

    # parse out the progress
    progress = Handbrake.get_encode_percent(data)
    save
  end

  def handle_encode_exit(data)
    update(state: 'successful')
    logs.last.update(complete: true)
  end

  def handle_encode_failed(data)
    update(state: 'failed')
    logs.last.update(complete: true)
  end
end
