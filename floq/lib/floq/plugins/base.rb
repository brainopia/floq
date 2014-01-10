module Floq::Plugins::Base
  attr_reader :adapter

  def initialize(provider, *args)
    @adapter = provider or raise ArgumentError
  end

  def method_missing(method, queue, *args, &block)
    @adapter.send method, queue, *args, &block
  end
end
