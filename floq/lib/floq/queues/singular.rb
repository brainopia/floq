class Floq::Queues::Singular < Floq::Queues::Base
  def pull
    message = peek
    if message
      yield message
      skip
      message
    end
  end
end
