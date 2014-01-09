class Floq::Plugins::Rescuers::DelayedRetry
  include Floq::Plugins::Base
  FAIL_TIMEOUT = 1

  def initialize(*)
    super
    @last_messages = {}
  end

  def peek_and_skip(queue)
    @adapter.peek_and_skip(queue).tap do |message,_|
      @last_messages[queue] = message
    end
  end

  def pull(queue, &block)
    if @delayed_retry
      if Time.now - @delayed_retry <= FAIL_TIMEOUT
        return
      else
        @delayed_retry = nil
        try_again = true
      end
    end

    begin
      if try_again
        block.call @last_messages[queue]
      else
        @adapter.pull queue, &block
      end
    rescue
      @delayed_retry = Time.now
    end
  end
end
