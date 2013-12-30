module Floq::Adapters::Memory
  extend self

  MESSAGES = Hash.new {|hash, key| hash[key] = [] }
  OFFSETS  = Hash.new 0
  CONFIRMS = MESSAGES.dup

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
    OFFSETS[queue].to_i
  end

  def offset!(queue, value)
    OFFSETS[queue] = value
  end

  def total(queue)
    MESSAGES[queue].length
  end

  def peek_and_skip(queue)
    [peek(queue), offset(queue)].tap do |message, offset|
      skip queue if message
    end
  end

  def confirm(queue, offset)
    CONFIRMS[queue] << offset
  end

  def confirmed_offset(queue)
    CONFIRMS[queue].min
  end

  def read(queue, from, count)
    MESSAGES[queue][from, count]
  end
end
