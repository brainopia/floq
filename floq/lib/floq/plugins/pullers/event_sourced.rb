class Floq::Plugins::Pullers::EventSourced
  include Floq::Plugins::Base

  def pull(queue)
    yield @base.peek(queue)
  end

  def peek(queue)
    events = @base.read queue, 0, 10_000
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

  def splittable?(_)
    true
  end
end
