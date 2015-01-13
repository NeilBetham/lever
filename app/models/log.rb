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

    EM::Synchrony.sync($REDIS.lrange(redis_key, 0, -1)).map { |part| MessagePack.unpack part }
  end

  def add_part(part)
    part_index = EM::Synchrony.sync $REDIS.llen(redis_key)

    msg = {
      type: 'log:addpart',
      part: {
        logId: id,
        index: part_index + 1,
        content: part
      }
    }

    LeverApp.settings.event_channel.push msg.to_json
    EM::Synchrony.sync $REDIS.rpush redis_key, { content: part, index: part_index + 1 }.to_msgpack
  end

  def commit_log
    data = EM::Synchrony.sync $REDIS.lrange(redis_key, 0, -1)
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
