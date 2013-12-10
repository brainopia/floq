class Floq::Queue::Parallel < Floq::Queue
  def pull
    message, offset = peek_and_skip
    yield message
    confirm offset
  end
end
