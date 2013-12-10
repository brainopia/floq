module Floq::Providers::Memory
  extend self

  MESSAGES = Hash.new {|hash, key| hash[key] = [] }
  OFFSETS  = Hash.new 0

  def peek(queue)
    MESSAGES[queue][offset queue]
  end

  def push(queue, message)
    MESSAGES[queue].push message
  end

  def drop(queue)
    MESSAGES.delete queue
    OFFSETS.delete queue
  end

  def skip(queue)
    OFFSETS[queue] += 1
  end

  def skip_all(queue)
    OFFSETS[queue] = total(queue)
  end

  def offset(queue)
    OFFSETS[queue]
  end

  def total(queue)
    MESSAGES[queue].length
  end
end
