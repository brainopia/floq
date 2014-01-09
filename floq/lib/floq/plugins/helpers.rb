class Floq::Plugins::Helpers
  include Floq::Plugins::Base

  def initialize(*)
    super
    @handlers = {}
  end

  def count(queue)
    @adapter.total(queue) - @adapter.offset(queue)
  end

  def peek_read(queue, count=10)
    @adapter.read queue, @adapter.offset(queue), count
  end

  def handle(queue, &block)
    @handlers[queue] = block
  end

  def handler(queue)
    @handlers[queue]
  end

  def pull_and_handle(queue)
    @adapter.pull(queue) {|data| handler(queue).call data }
  end
end
