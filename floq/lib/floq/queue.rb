class Floq::Queue
  require_relative 'queue/_extending/provider'
  require_relative 'queue/parallel'
  require_relative 'queue/singular'

  include Floq::Serializer

  attr_reader :name
  delegate_provider :drop, :skip, :skip_all, :offset, :total

  def initialize(name)
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
end
