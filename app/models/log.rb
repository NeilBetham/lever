class Log < ActiveRecord::Base
  belongs_to :job
  serialize :parts

  def add_part(part)
    EM.synchrony do
      current_parts = MessagePack.unpack(REDIS.get(redis_key)) unless REDIS.get(redis_key).nil?
      current_parts ||= []
      current_parts.append(data: part, number: current_parts.length + 1)
      REDIS.set redis_key, current_parts.to_msgpack
    end
  end

  def cached_parts
    ret = []
    if complete
      return parts
    else
      EM.synchrony do
        ret = MessagePack.unpack REDIS.get(redis_key) unless REDIS.get(redis_key).nil?
      end
    end
    ret
  end

  def commit_log
    EM.synchrony do
      current_parts = MessagePack.unpack REDIS.get(redis_key)
      update(parts: current_parts)
    end
  end

  def redis_key
    "job-#{job.id}_log-#{id}_parts"
  end
end
