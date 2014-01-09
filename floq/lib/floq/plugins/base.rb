module Floq::Plugins::Base
  def initialize(provider)
    @adapter = provider or raise ArgumentError
  end

  def method_missing(method, queue, *args, &block)
    @adapter.send method, queue, *args, &block
  end
end
