class Floq::Queues::Parallel < Floq::Queues::Base
  delegate_provider :confirmed_offset
  prepend DelayedRetry

  def pull
    message, offset = peek_and_skip
    if message
      yield message
      confirm offset
      message
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
