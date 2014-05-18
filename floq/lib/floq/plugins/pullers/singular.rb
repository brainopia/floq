class Floq::Plugins::Pullers::Singular
  include Floq::Plugins::Base

  def pull(queue)
    message = @base.peek queue
    if message
      yield message
      @base.skip queue
      message
    end
  end

  def splittable?(_)
    false
  end

  def cleanup(queue)
    @base.cleanup queue, :singular
  end
end
