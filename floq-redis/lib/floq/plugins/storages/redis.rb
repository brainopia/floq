class Floq::Plugins::Storages::Redis
  attr_reader :settings

  def initialize(settings={})
    @settings = settings
    @digests = {}
  end

  def peek(queue)
    redis_eval <<-LUA, [queue, offset_key(queue)]
      local queue      = table.remove(ARGV, 1)
      local offset_key = table.remove(ARGV, 1)
      local offset     = redis.call('get', offset_key) or 0

      return redis.call('lindex', queue, tonumber(offset))
    LUA
  end

  def push(queue, message)
    client.rpush queue, message
  end

  def drop(queue)
    client.multi do
      client.del queue
      client.del offset_key(queue)
      client.del offset_base_key(queue)
      client.del recover_offset_key(queue)
      client.del confirm_key(queue)
    end
  end

  def skip(queue)
    # TODO: use hincrby
    client.incr offset_key(queue)
  end

  # TODO: support confirmations
  def skip_all(queue)
    client.set offset_key(queue), dirty_total(queue)
  end

  def offset(queue)
    redis_eval <<-LUA, [offset_base_key(queue), offset_key(queue)]
      local base_key   = table.remove(ARGV, 1)
      local offset_key = table.remove(ARGV, 1)
      local base       = redis.call('get', base_key) or 0
      local offset     = redis.call('get', offset_key) or 0

      return tonumber(base) + tonumber(offset)
    LUA
  end

  def dirty_offset(queue)
    client.get(offset_key queue).to_i
  end

  def offset!(queue, value)
    redis_eval <<-LUA, [offset_base_key(queue), offset_key(queue), value]
      local base_key   = table.remove(ARGV, 1)
      local offset_key = table.remove(ARGV, 1)
      local value      = tonumber(table.remove(ARGV, 1))
      local base       = tonumber(redis.call('get', base_key) or 0)

      if value < base then
        return { err = "Value is less than offset base" }
      else
        redis.call('set', offset_key, value - base)
      end
    LUA
  end

  def total(queue)
    redis_eval <<-LUA, [queue, offset_base_key(queue)]
      local queue    = table.remove(ARGV, 1)
      local base_key = table.remove(ARGV, 1)
      local tasks    = redis.call('llen', queue)
      local base     = redis.call('get', base_key) or 0

      return tasks + tonumber(base)
    LUA
  end

  def dirty_total(queue)
    client.llen queue
  end

  def peek_and_skip(queue)
    redis_eval <<-LUA, [queue.to_s, offset_key(queue), offset_base_key(queue)]
      local queue      = table.remove(ARGV, 1)
      local offset_key = table.remove(ARGV, 1)
      local base_key   = table.remove(ARGV, 1)
      local offset     = redis.call('get', offset_key) or 0
      local message    = redis.call('lindex', queue, offset)

      if message then
        local base = redis.call('get', base_key) or 0
        redis.call('incr', offset_key)
        return { message, tonumber(base) + tonumber(offset) }
      end
    LUA
  end

  def recover(queue)
    # fix this awful code
    redis_eval <<-LUA, [queue.to_s, offset_base_key(queue), recover_offset_key(queue), confirm_key(queue)]
      local queue       = table.remove(ARGV, 1)
      local base_key    = table.remove(ARGV, 1)
      local recover_key = table.remove(ARGV, 1)
      local confirm_key = table.remove(ARGV, 1)
      local confirms    = redis.call('get', confirm_key)

      if confirms then
        local recover_offset = redis.call('get', recover_key) or 0
        local recover_byte   = math.floor(recover_offset / 8)
        local recover_bit    = recover_offset - recover_byte * 8
        local position
        local byte

        for byte_index=recover_byte, #confirms - 1 do
          byte = string.byte(confirms, byte_index + 1)

          for bit_index=recover_bit, 7 do
            if byte % 2^(7-bit_index+1) < 2^(7-bit_index) then
              position = byte_index*8 + bit_index
              break
            end
          end

          if position then
            break
          end

          recover_bit = 0
        end

        if position then
          local message = redis.call('lindex', queue, position)
          local base = redis.call('get', base_key) or 0

          redis.call('set', recover_key, position + 1)
          return { message, tonumber(base) + tonumber(position) }
        end
      end
    LUA
  end

  def confirm(queue, offset)
    redis_eval <<-LUA, [confirm_key(queue), offset_base_key(queue), offset]
      local confirm_key = table.remove(ARGV, 1)
      local base_key    = table.remove(ARGV, 1)
      local offset      = tonumber(table.remove(ARGV, 1))
      local base        = tonumber(redis.call('get', base_key) or 0)

      if base <= offset then
        redis.call('setbit', confirm_key, offset - base, 1)
      end
    LUA
  end

  def read(queue, from, count)
    redis_eval <<-LUA, [queue.to_s, offset_base_key(queue), from, count]
      local queue      = table.remove(ARGV, 1)
      local base_key   = table.remove(ARGV, 1)
      local base       = tonumber(redis.call('get', base_key) or 0)
      local from       = tonumber(table.remove(ARGV, 1)) - base
      local count      = tonumber(table.remove(ARGV, 1))

      return redis.call('lrange', queue, from, from + count - 1)
    LUA
  end

  def cleanup(queue, type=:default)
    case type
    when :singular
      redis_eval <<-LUA, [queue.to_s, offset_key(queue), offset_base_key(queue)]
        local queue      = table.remove(ARGV, 1)
        local offset_key = table.remove(ARGV, 1)
        local base_key   = table.remove(ARGV, 1)
        local offset     = redis.call('get', offset_key)

        if offset and offset ~= 0 then
          redis.call('del', offset_key)
          redis.call('incrby', base_key, offset)
          redis.call('ltrim', queue, offset, -1)
        end
      LUA
    when :parallel
      # fix this awful code
      redis_eval <<-LUA, [queue.to_s, offset_key(queue), offset_base_key(queue), recover_offset_key(queue), confirm_key(queue)]
        local queue       = table.remove(ARGV, 1)
        local offset_key  = table.remove(ARGV, 1)
        local base_key    = table.remove(ARGV, 1)
        local recover_key = table.remove(ARGV, 1)
        local confirm_key = table.remove(ARGV, 1)
        local offset      = redis.call('get', offset_key)
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

          redis.call('set', recover_key, 0)

          if cursor > 1 then
            local deletedConfirmations = (cursor-1)*8

            redis.call('incrby', base_key, deletedConfirmations)
            redis.call('set', offset_key, offset - deletedConfirmations)
            redis.call('set', confirm_key, string.sub(confirms, cursor, -1))
            redis.call('ltrim', queue, deletedConfirmations, -1)
          end
        end
      LUA
    end
  end

  private

  def offset_key(queue)
    "#{queue}-offset"
  end

  def recover_offset_key(queue)
    "#{queue}-recover-offset"
  end

  def confirm_key(queue)
    "#{queue}-confirm"
  end

  def offset_base_key(queue)
    "#{queue}-offset-base"
  end

  def client
    Thread.current[:floq_redis_client] ||= Redis.new settings
  end

  def redis_eval(script, args)
    begin
      @digests[script] ||= Digest::SHA1.hexdigest script
      client.evalsha @digests[script], argv: args
    rescue Redis::CommandError => error
      raise unless error.message.include? 'NOSCRIPT'
      client.eval script, argv: args
    end
  end
end
