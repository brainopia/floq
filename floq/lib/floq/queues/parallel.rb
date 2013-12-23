class Floq::Queues::Parallel < Floq::Queues::Base
  FAIL_TIMEOUT = 1

  delegate_provider :confirmed_offset

  def pull
    if @failed
      if Time.now - @failed <= FAIL_TIMEOUT
        return
      else
        @failed = nil
      end
    end

    message, offset = peek_and_skip
    if message
      begin
        yield message
        confirm offset
        message
      rescue
        @failed_at = Time.now
      end
    end
  end

  def confirm(offset)
    provider.confirm name, offset
  end

  def peek_and_skip
    message, offset = provider.peek_and_skip name
    [decode(message), offset] if message
  end
end
