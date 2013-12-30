module Floq::Queues::Base::DelayedRetry
  FAIL_TIMEOUT = 1

  def pull
    if @delayed_retry
      if Time.now - @delayed_retry <= FAIL_TIMEOUT
        return
      else
        @delayed_retry = nil
      end
    end

    begin
      super
    rescue
      @delayed_retry = Time.now
    end
  end
end
