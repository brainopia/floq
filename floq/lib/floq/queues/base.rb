class Floq::Queues::Base
  include Floq::Serializer
  require_relative 'base/_extending/provider'

  attr_reader :label, :name, :handler
  delegate_provider :drop, :skip, :skip_all, :offset, :total

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
    message = provider.peek name
    decode message if message
  end

  def offset!(value)
    provider.offset! name, value
  end

  def push(message)
    encoded = encode message
    provider.push name, encoded
  end

  def handle(&block)
    @handler = block
  end

  def pull_and_handle
    pull {|data| handler.call data }
  end
end
