class Floq::Plugins::Storages::Memory
  attr_reader :messages, :offsets, :confirms

  def initialize
    @messages = Hash.new {|hash, key| hash[key] = [] }
    @offsets  = Hash.new 0
    @confirms = messages.dup
  end

  def peek(queue)
    messages[queue][offset queue]
  end

  def push(queue, message)
    messages[queue].push message
  end

  def drop(queue)
    messages.delete queue
    offsets.delete queue
  end

  def skip(queue)
    offsets[queue] += 1
  end

  def skip_all(queue)
    offsets[queue] = total queue
  end

  def offset(queue)
    offsets[queue]
  end

  def offset!(queue, value)
    offsets[queue] = value
  end

  def total(queue)
    messages[queue].length
  end

  def peek_and_skip(queue)
    [peek(queue), offset(queue)].tap do |message, offset|
      skip queue if message
    end
  end

  def recover(queue)
  end

  def confirm(queue, offset)
    confirms[queue] << offset
  end

  def read(queue, from, count)
    messages[queue][from, count]
  end

  def cleanup(queue, type)
    offsets[queue] = 0
    messages[queue].clear
    confirms[queue].clear
  end
end
