class Floq::Queues::Singular < Floq::Queues::Base
  prepend DelayedRetry

  def pull
    message = peek
    if message
      yield message
      skip
      message
    end
  end
end
