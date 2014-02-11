class Floq::Plugins::Adapters::Redis
  attr_reader :pool

  def initialize(settings={})
    @pool = new_pool settings.dup
  end

  def peek(queue)
    pool.with do |client|
      client.lindex queue, offset(queue)
    end
  end

  def push(queue, message)
    pool.with do |client|
      client.rpush queue, message
    end
  end

  def drop(queue)
    pool.with do |client|
      client.multi do
        client.del queue
        client.del offset_key(queue)
        client.del confirm_key(queue)
      end
    end
  end

  def skip(queue)
    pool.with do |client|
      # TODO: use hincrby
      client.incr offset_key(queue)
    end
  end

  def skip_all(queue)
    pool.with do |client|
      client.set offset_key(queue), total(queue)
    end
  end

  def offset(queue)
    pool.with do |client|
      client.get(offset_key queue).to_i
    end
  end

  def offset!(queue, value)
    pool.with do |client|
      client.set offset_key(queue), value
    end
  end

  def total(queue)
    pool.with do |client|
      client.llen queue
    end
  end

  def peek_and_skip(queue)
    pool.with do |client|
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
  end

  def confirm(queue, offset)
    pool.with do |client|
      client.setbit confirm_key(queue), offset, 1
    end
  end

  def read(queue, from, count)
    pool.with do |client|
      client.lrange queue, from, from + count - 1
    end
  end

  def cleanup(queue, type=:default)
    case type
    when :singular
      pool.with do |client|
        client.eval <<-LUA, argv: [queue.to_s, offset_key(queue)]
          local queue      = table.remove(ARGV, 1)
          local offset_key = table.remove(ARGV, 1)
          local offset     = redis.call('get', offset_key)

          if offset and offset != 0 then
            redis.call('del', offset_key)
            redis.call('ltrim', queue, offset, -1)
          end
        LUA
      end
    when :parallel
      pool.with do |client|
        # TODO: evalsha
        client.eval <<-LUA, argv: [queue.to_s, offset_key(queue), confirm_key(queue)]
          local queue       = table.remove(ARGV, 1)
          local offset_key  = table.remove(ARGV, 1)
          local confirm_key = table.remove(ARGV, 1)
          local confirms    = redis.call('get', confirm_key)
          local cursor      = 1

          if confirms then
            while true do
              if string.byte(confirms, cursor) == 255 then
                cursor = cursor + 1
              else
                break
              end
            end

            if cursor > 1 then
              local deletedConfirmations = (cursor-1)*8
              local new_offset = offset - deletedConfirmations

              redis.call('set', offset_key, new_offset)
              redis.call('set', string.sub(confirms, cursor, -1))
              redis.call('ltrim', queue, deletedConfirmations, -1)
            end
          end
        LUA
      end
    end
  end

  private

  def offset_key(queue)
    "#{queue}-offset"
  end

  def confirm_key(queue)
    "#{queue}-confirm"
  end

  def new_pool(settings)
    pool_settings = settings.delete(:pool) || {}
    pool_settings[:size]    ||= 10
    pool_settings[:timeout] ||= 5

    ConnectionPool.new pool_settings do
      Redis.new settings
    end
  end
end
