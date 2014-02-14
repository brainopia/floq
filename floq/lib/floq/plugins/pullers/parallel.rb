class Floq::Plugins::Pullers::Parallel
  include Floq::Plugins::Base

  def initialize(*)
    super
    @recovered = {}
  end

  def pull(queue)
    if @recovered[queue]
      message, offset = @adapter.peek_and_skip queue
      if message
        yield message
        @adapter.confirm queue, offset
        message
      end
    else
      message, offset = @adapter.recover queue
      if message
        yield message
        @adapter.confirm queue, offset
        message
      else
        @recovered[queue] = true
        pull(queue) {|message| yield message }
      end
    end
  end

  def splittable?(_)
    true
  end

  def cleanup(queue)
    @adapter.cleanup queue, :parallel
  end
end
