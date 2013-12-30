class Floq::Queues::Base
  include Floq::Serializer
  require_relative 'base/_extending/adapter'
  require_relative 'base/delayed_retry'

  attr_reader :label, :name, :handler
  delegate_adapter :drop, :skip, :skip_all, :offset, :total

  def initialize(label)
    raise ArgumentError, label unless label
    @label = label
    @name  = "floq-#{label}"
  end

  def start
  end

  def count
    total - offset
  end

  def peek
    message = adapter.peek name
    decode message if message
  end

  def offset!(value)
    adapter.offset! name, value
  end

  def push(message)
    encoded = encode message
    adapter.push name, encoded
  end

  def handle(&block)
    @handler = block
  end

  def pull_and_handle
    pull {|data| handler.call data }
  end

  def read(from: offset, count: 10)
    adapter.read(name, from, count).map &method(:decode)
  end
end
