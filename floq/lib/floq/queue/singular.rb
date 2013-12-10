class Floq::Queue::Singular < Flow::Queue
  def pull
    yield peek
    skip
  end
end
