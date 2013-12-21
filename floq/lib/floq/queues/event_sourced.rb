class Floq::Queues::EventSourced < Floq::Queues::Base
  def pull
    yield peek
  end

  def peek
    events = provider.all name
    merged = events.reduce {|total, event| total.merge event }
    merged.delete_if {|_, value| value.nil? }
  end

  def skip
    raise 'unsupported'
  end

  def skip_all
    raise 'unsupported'
  end

  def offset
    0
  end
end
