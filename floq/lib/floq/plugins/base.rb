module Floq::Plugins::Base
  attr_reader :base

  def initialize(base, *args)
    @base = base or raise ArgumentError
  end

  def method_missing(method, queue=nil, *args, &block)
    raise NoMethodError, method unless queue
    @base.send method, queue, *args, &block
  end
end
