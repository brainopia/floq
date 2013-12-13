class Floq::Schedulers::Base
  attr_reader :queues

  def initialize(queues=[])
    @queues = []
    add queues
  end

  def add(queues)
    check_handler queues
    @queues.concat queues
  end

  private

  def check_handler(queues)
    without_handler = queues.reject(&:handler)
    unless without_handler.empty?
      raise ArgumentError, "Missing handler for #{without_handler}"
    end
  end
end
