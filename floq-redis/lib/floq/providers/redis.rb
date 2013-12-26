require 'floq'
require 'redis'

class Floq::Providers::Redis
  def initialize(settings={})
    @settings = settings
  end

  def peek(queue)
    client.lindex queue, offset(queue)
  end

  def push(queue, message)
    client.rpush queue, message
  end

  def drop(queue)
    client.multi do
      client.del queue
      client.del offset_key(queue)
      client.del confirm_key(queue)
    end
  end

  def skip(queue)
    # TODO: use hincrby
    client.incr offset_key(queue)
  end

  def skip_all(queue)
    client.set offset_key(queue), total(queue)
  end

  def offset(queue)
    client.get(offset_key queue).to_i
  end

  def offset!(queue, value)
    client.set offset_key(queue), value
  end

  def total(queue)
    client.llen queue
  end

  def peek_and_skip(queue)
    # TODO: evalsha
    client.eval <<-LUA, argv: [queue.to_s, offset_key(queue)]
      local queue      = table.remove(ARGV, 1)
      local offset_key = table.remove(ARGV, 1)
      local offset     = redis.call('get', offset_key) or 0
      local message    = redis.call('lindex', queue, offset)

      if message then
        redis.call('incr', offset_key)
      end

      return { message, tonumber(offset) }
    LUA
  end

  def confirm(queue, offset)
    client.rpush confirm_key(queue), offset
  end

  def confirmed_offset(queue)
    client.lrange(confirm_key(queue), 0, -1).map(&:to_i).min
  end

  def read(queue, from, count)
    client.lrange queue, from, from + count - 1
  end

  private

  def offset_key(queue)
    "#{queue}-offset"
  end

  def confirm_key(queue)
    "#{queue}-confirm"
  end

  def client
    Thread.current[:floq_redis] ||= Redis.new @settings
  end
end
