class Floq::Schedulers::Base
  attr_reader :options, :queues

  def initialize(options={})
    @options = options
    @queues  = options.delete(:queues) { [] }
  end

  def run
    loop { pull_and_handle }
  end

  private

  def check_handler
    without_handler = queues.reject(&:handler)
    unless without_handler.empty?
      raise ArgumentError, "Missing handler for #{without_handler}"
    end
  end
end
