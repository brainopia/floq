class Floq::Plugins::Pullers::Singular
  include Floq::Plugins::Base

  def pull(queue)
    message = @adapter.peek queue
    if message
      yield message
      @adapter.skip queue
      message
    end
  end
end
