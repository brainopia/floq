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
    pull(queue) {|data| handler(queue).call data }
  end

  def pull(queue, &block)
    raise ArgumentError, <<-ERROR unless block
      pull from #{queue} without a block
    ERROR

    pulled = false

    @adapter.pull queue do |message|
      pulled = true
      block.call message
    end

    pulled
  end
end
