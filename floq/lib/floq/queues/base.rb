class Floq::Queues::Base
  include Floq::Serializer
  require_relative 'base/_extending/provider'

  attr_reader :name, :handler
  delegate_provider :drop, :skip, :skip_all, :offset, :total

  def initialize(name)
    raise ArgumentError, name unless name
    @name = "floq-#{name}"
  end

  def count
    total - offset
  end

  def peek
    message = provider.peek name
    decode message if message
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
