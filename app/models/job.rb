class Job < ActiveRecord::Base
  include Streamable

  JOB_STATES = %i(queued encoding failed successful canceled)
  has_many :logs
  validate :validates_only_one_encoding_job

  scope :queued, -> { where(state: 'queued') }

  def encode
    info "starting encode of #{name}"

    # Return if another job is already encoding
    return if !Job.encoding.nil? && Job.encoding.id != id

    # Encode was restarted, create new log
    logs.create

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

  def current_log
    logs.last || Log.new
  end

  def stop
    Signal.trap('INT') {}
    Process.kill 'INT', 0
  end

  def self.next_job_to_encode
    if Job.encoding
      nil
    else
      queued.first
    end
  end

  def self.encoding
    where(state: 'encoding').first
  end

  private

  def handle_command_output(data)
    # add part to log
    logs.create if logs.empty?
    current_log.add_part data

    # parse out the progress
    progress = Handbrake.get_encode_percent(data)
    update(progress: progress) unless progress.nil?
  end

  def handle_encode_exit(data)
    update(state: 'successful')
    current_log.update(complete: true)
    EM.next_tick do
      EM.synchrony do
        current_log.commit_log
      end
    end
  end

  def handle_encode_failed(data)
    update(state: 'failed') unless state == 'queued'
    error "encode failed - #{data}"
    current_log.update(complete: true)
    current_log.commit_log
  end

  def validates_only_one_encoding_job
    errors.add(:job, 'only one job can be encoding at a time') if Job.where(state: 'encoding').count > 1
  end
end
