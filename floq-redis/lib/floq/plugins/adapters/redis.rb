class Floq::Plugins::Adapters::Redis
  attr_reader :pool

  def initialize(settings={})
    @pool = new_pool settings.dup
  end

  def peek(queue)
    pool.with do |client|
      client.lindex queue, dirty_offset(queue)
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
        client.del offset_base_key(queue)
        client.del recover_offset_key(queue)
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

  # TODO: support confirmations
  def skip_all(queue)
    pool.with do |client|
      client.set offset_key(queue), dirty_total(queue)
    end
  end

  def offset(queue)
    pool.with do |client|
      client.eval <<-LUA, argv: [offset_base_key(queue), offset_key(queue)]
        local base_key   = table.remove(ARGV, 1)
        local offset_key = table.remove(ARGV, 1)
        local base       = redis.call('get', base_key) or 0
        local offset     = redis.call('get', offset_key) or 0

        return tonumber(base) + tonumber(offset)
      LUA
    end
  end

  def dirty_offset(queue)
    pool.with do |client|
      client.get(offset_key queue).to_i
    end
  end

  def offset!(queue, value)
    pool.with do |client|
      client.eval <<-LUA, argv: [offset_base_key(queue), offset_key(queue), value]
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
  end

  def total(queue)
    pool.with do |client|
      client.eval <<-LUA, argv: [queue, offset_base_key(queue)]
        local queue    = table.remove(ARGV, 1)
        local base_key = table.remove(ARGV, 1)
        local tasks    = redis.call('llen', queue)
        local base     = redis.call('get', base_key) or 0

        return tasks + tonumber(base)
      LUA
    end
  end

  def dirty_total(queue)
    pool.with do |client|
      client.llen queue
    end
  end

  def peek_and_skip(queue)
    pool.with do |client|
      # TODO: evalsha
      client.eval <<-LUA, argv: [queue.to_s, offset_key(queue), offset_base_key(queue)]
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
  end

  def recover(queue)
    pool.with do |client|
      # TODO: evalsha
      # fix this awful code
      client.eval <<-LUA, argv: [queue.to_s, offset_base_key(queue), recover_offset_key(queue), confirm_key(queue)]
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
            local base = redis.call('get', base_key) || 0

            redis.call('set', recover_key, position + 1)
            return { message, tonumber(base) + tonumber(position) }
          end
        end
      LUA
    end
  end

  def confirm(queue, offset)
    pool.with do |client|
      client.eval <<-LUA, argv: [confirm_key(queue), offset_base_key(queue), offset]
        local confirm_key = table.remove(ARGV, 1)
        local base_key    = table.remove(ARGV, 1)
        local offset      = tonumber(table.remove(ARGV, 1))
        local base        = tonumber(redis.call('get', base_key) or 0)

        if base <= offset then
          redis.call('setbit', confirm_key, offset - base, 1)
        end
      LUA
    end
  end

  # TODO: take into account offset_base
  def read(queue, from, count)
    pool.with do |client|
      client.lrange queue, from, from + count - 1
    end
  end

  def cleanup(queue, type=:default)
    case type
    when :singular
      pool.with do |client|
        client.eval <<-LUA, argv: [queue.to_s, offset_key(queue), offset_base_key(queue)]
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
      end
    when :parallel
      pool.with do |client|
        # TODO: evalsha
        # fix this awful code
        client.eval <<-LUA, argv: [queue.to_s, offset_key(queue), offset_base_key(queue), recover_offset_key(queue), confirm_key(queue)]
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

  def new_pool(settings)
    pool_settings = settings.delete(:pool) || {}
    pool_settings[:size]    ||= 10
    pool_settings[:timeout] ||= 5

    ConnectionPool.new pool_settings do
      Redis.new settings
    end
  end
end
