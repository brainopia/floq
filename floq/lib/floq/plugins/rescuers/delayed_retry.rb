class Floq::Plugins::Rescuers::DelayedRetry
  include Floq::Plugins::Base
  FAIL_TIMEOUT = 1

  def initialize(adapter, callback=nil)
    super
    @messages = {}
    @retries = {}
    @callback = callback
  end

  def pull(queue, &block)
    if @retries[queue]
      if Time.now - @retries[queue] <= FAIL_TIMEOUT
        return
      else
        @retries[queue] = nil
        try_again = true
      end
    end

    begin
      if try_again and @messages[queue]
        block.call @messages[queue]
      else
        @adapter.pull queue do |message|
          @messages[queue] = message
          block.call message
        end
      end
    rescue
      @retries[queue] = Time.now
      @callback.call queue, $! if @callback
    end
  end
end
