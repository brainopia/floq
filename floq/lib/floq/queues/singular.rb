class Floq::Queues::Singular < Floq::Queues::Base
  FAIL_TIMEOUT = 1

  def pull
    if @failed
      if Time.now - @failed <= FAIL_TIMEOUT
        return
      else
        @failed = nil
      end
    end

    message = peek
    if message
      begin
        yield message
        skip
        message
      rescue
        @failed = Time.now
      end
    end
  end
end
