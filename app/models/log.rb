class Log < ActiveRecord::Base
  include Streamable

  before_create :init_properties

  belongs_to :job
  serialize :parts

  def parts=(parts)
    write_attribute(:parts, parts)
  end

  def parts
    return read_attribute(:parts) if complete

    data = REDIS.lrange(redis_key, 0, -1)
    data.map { |part| MessagePack.unpack part }
  end

  def add_part(part)
    part_index = REDIS.llen(redis_key)
    part_index = part_index.is_a?(Numeric) ? part_index : part_index.length # llen sometimes returns the array at the key

    msg = {
      type: 'log:addpart',
      part: {
        logId: id,
        index: part_index + 1,
        content: part
      }
    }

    LeverApp.settings.event_channel.push msg.to_json
    REDIS.rpush redis_key, { content: part, index: part_index + 1 }.to_msgpack
  end

  def commit_log
    data = REDIS.lrange(redis_key, 0, -1)
    current_parts = data.map { |part| MessagePack.unpack part }
    update(parts: current_parts)
  end

  def redis_key
    "log-#{id}_parts"
  end

  private

  def init_properties
    self.parts = []
  end
end
