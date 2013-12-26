class Floq::Queues::EventSourced < Floq::Queues::Base
  def pull
    yield peek
  end

  def peek
    events = read count: 10_000
    raise 'too much events' if events.size == 10_000
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
