require 'floq'
require 'redis'

module Floq::Providers::Redis
  extend self

  Floq.provider = self

  def peek(queue)
    client.lindex queue, offset(queue)
  end

  def push(queue, message)
    client.rpush queue, message
  end

  def drop(queue)
    client.del queue
    client.del offset_key(queue)
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

  def total(queue)
    client.llen queue
  end

  private

  def offset_key(queue)
    "#{queue}-offset"
  end

  def client
    Thread.current[:floq_redis] ||= Redis.new
  end
end
