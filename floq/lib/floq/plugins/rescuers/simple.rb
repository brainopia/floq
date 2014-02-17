class Floq::Plugins::Rescuers::Simple
  include Floq::Plugins::Base

  def initialize(adapter, callback=nil)
    super
    @callback = callback
  end

  def pull(queue, &block)
    @adapter.pull queue, &block
  rescue
    @callback.call queue, $! if @callback
  end
end
