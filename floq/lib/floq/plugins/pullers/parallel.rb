class Floq::Plugins::Pullers::Parallel
  include Floq::Plugins::Base

  def initialize(*)
    super
    @recovered = {}
  end

  def pull(queue)
    if @recovered[queue]
      message, offset = @base.peek_and_skip queue
      if message
        yield message
        @base.confirm queue, offset
        message
      end
    else
      message, offset = @base.recover queue
      if message
        yield message
        @base.confirm queue, offset
        message
      else
        @recovered[queue] = true
        pull(queue) {|message| yield message }
      end
    end
  rescue
    @recovered[queue] = false
    raise
  end

  def splittable?(_)
    true
  end

  def cleanup(queue)
    @base.cleanup queue, :parallel
  end
end
