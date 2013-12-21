class Floq::Schedulers::Periodic < Floq::Schedulers::Base
  attr_reader :period

  def initialize(*)
    super
    @period = options.fetch :interval
  end

  def pull_and_handle
    queues.each(&:pull_and_handle)
    sleep period
  end
end
