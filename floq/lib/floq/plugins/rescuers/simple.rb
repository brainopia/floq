class Floq::Plugins::Rescuers::Simple
  include Floq::Plugins::Base

  def initialize(base, callback=nil)
    super
    @callback = callback
  end

  def pull(queue, &block)
    @base.pull queue, &block
  rescue
    @callback.call queue, $! if @callback
    false
  end
end
