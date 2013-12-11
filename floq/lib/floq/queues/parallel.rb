class Floq::Queues::Parallel < Floq::Queues::Base
  def pull
    message, offset = peek_and_skip
    yield message
    confirm offset
  end
end
