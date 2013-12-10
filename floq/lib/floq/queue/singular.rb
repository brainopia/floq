class Floq::Queue::Singular < Floq::Queue
  def pull
    message = peek
    if message
      yield message
      skip
      message
    end
  end
end
