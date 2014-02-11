class Floq::Plugins::Pullers::Parallel
  include Floq::Plugins::Base

  def pull(queue)
    message, offset = @adapter.peek_and_skip queue
    if message
      yield message
      @adapter.confirm queue, offset
      message
    end
  end

  def splittable?(_)
    true
  end

  def cleanup(queue)
    cleanup queue, :parallel
  end
end
