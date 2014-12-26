class Log < ActiveRecord::Base
  belongs_to :job
  serialize :parts

  def add_part(part)
    current_parts = MessagePack.unpack(REDIS.get(redis_key)) unless REDIS.get(redis_key).nil?
    current_parts ||= []
    current_parts.append(data: part, number: current_parts.length + 1)
    REDIS.set redis_key, current_parts.to_msgpack
  end

  def cached_parts
    return parts if complete

    data = REDIS.get(redis_key)
    MessagePack.unpack(data)
  end

  def commit_log
    current_parts = MessagePack.unpack REDIS.get(redis_key)
    update(parts: current_parts)
  end

  def redis_key
    "job-#{job.id}_log-#{id}_parts"
  end
end
