class Floq::Queues::Parallel < Floq::Queues::Base
  def pull
    message, offset = peek_and_skip
    yield message
    confirm offset
  end

  def confirm(offset)
    provider.confirm name, offset
  end

  def peek_and_skip
    message, offset = provider.peek_and_skip name
    [decode(message), offset] if message
  end
end
