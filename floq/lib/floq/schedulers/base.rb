class Floq::Schedulers::Base
  attr_reader :queues

  def initialize(queues)
    @queues = queues
    check_handler
  end

  private

  def check_handler
    without_handler = queues.reject(&:handler)
    unless without_handler.empty?
      raise ArgumentError, "Missing handler for #{without_handler}"
    end
  end
end
