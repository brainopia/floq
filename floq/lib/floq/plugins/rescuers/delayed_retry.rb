class Floq::Plugins::Rescuers::DelayedRetry
  include Floq::Plugins::Base
  FAIL_TIMEOUT = 1

  def initialize(*)
    super
    @last_messages = {}
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
        @adapter.pull queue do |message|
          @last_messages[queue] = message
          block.call message
        end
      end
    rescue
      @delayed_retry = Time.now
    end
  end
end
